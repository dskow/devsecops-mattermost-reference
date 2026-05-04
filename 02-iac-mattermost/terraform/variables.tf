variable "region" {
  description = "AWS region. For Guard programs, override to us-gov-west-1."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "data_classification" {
  description = "Data classification tag applied to all resources (CUI, U, etc.)."
  type        = string
  default     = "CUI"
}

variable "vpc_cidr" {
  description = "CIDR block for the Mattermost VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the Mattermost app server."
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "STIG-hardened AMI ID. Default is a placeholder; supply via tfvars."
  type        = string
  default     = "ami-PLACEHOLDER"
}

variable "db_instance_class" {
  description = "RDS instance class for the Mattermost Postgres database."
  type        = string
  default     = "db.t3.medium"
}

variable "db_password" {
  description = "Master password for the Mattermost Postgres database."
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR ranges allowed to reach the ALB and SSH. Default to enclave management ranges in production."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
