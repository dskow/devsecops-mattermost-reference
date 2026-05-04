# Example tfvars for the Mattermost stack.
# Copy to terraform.tfvars and fill in real values. terraform.tfvars is gitignored.

environment         = "dev"
data_classification = "CUI"

# us-gov-west-1 for GovCloud
region = "us-east-1"

# AMI ID — for production, use a STIG-hardened AMI from your image pipeline.
# For testing you can resolve the latest Amazon Linux 2023 AMI via SSM:
#   aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query 'Parameter.Value' --output text
ami_id = "ami-REPLACE_ME"

# DB password — DO NOT commit a real value. Either supply via TF_VAR_db_password
# env var or pull from AWS Secrets Manager / Vault.
db_password = "REPLACE_ME_OR_USE_TF_VAR_DB_PASSWORD"

# ACM certificate ARN for the ALB HTTPS listener.
# Issue or import via the program's PKI process.
acm_certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/REPLACE_ME"

# Restrict to enclave management ranges in production.
allowed_cidr_blocks = ["10.0.0.0/8"]
