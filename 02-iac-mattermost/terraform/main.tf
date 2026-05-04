terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
      Workload    = "mattermost"
      ManagedBy   = "terraform"
      DataClass   = var.data_classification
    }
  }
}

locals {
  name_prefix = "mm-${var.environment}"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${local.name_prefix}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${local.name_prefix}-private-${count.index}" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "mattermost" {
  description             = "Mattermost data at rest (RDS, S3, EBS)"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = { Name = "${local.name_prefix}-kms" }
}

resource "aws_kms_alias" "mattermost" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.mattermost.key_id
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow Mattermost app to reach Postgres"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_db_instance" "mattermost" {
  identifier              = "${local.name_prefix}-db"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = var.db_instance_class
  allocated_storage       = 100
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.mattermost.arn
  db_name                 = "mattermost"
  username                = "mmadmin"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = 30
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "${local.name_prefix}-final"
}

# -----------------------------------------------------------------------------
# Application server
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Mattermost app server"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8065
    to_port         = 8065
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH from approved management ranges only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mattermost" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.mattermost.name

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = aws_kms_key.mattermost.arn
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "${local.name_prefix}-app" }
}

# -----------------------------------------------------------------------------
# Load balancer
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public-facing ALB for Mattermost"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
}

resource "aws_lb" "mattermost" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  drop_invalid_header_fields = true
  enable_deletion_protection = true
}

# -----------------------------------------------------------------------------
# File storage
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name_prefix}-uploads"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.mattermost.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# IAM for instance access to S3 + KMS
# -----------------------------------------------------------------------------

resource "aws_iam_role" "mattermost" {
  name = "${local.name_prefix}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "mattermost" {
  name = "${local.name_prefix}-profile"
  role = aws_iam_role.mattermost.name
}

resource "aws_iam_role_policy" "mattermost" {
  name = "${local.name_prefix}-policy"
  role = aws_iam_role.mattermost.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.uploads.arn, "${aws_s3_bucket.uploads.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.mattermost.arn
      }
    ]
  })
}
