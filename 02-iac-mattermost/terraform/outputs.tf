output "alb_dns_name" {
  description = "Public DNS name of the Mattermost ALB. Point the program's CNAME at this."
  value       = aws_lb.mattermost.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint for the Mattermost database. Used by the app server config."
  value       = aws_db_instance.mattermost.endpoint
  sensitive   = true
}

output "app_instance_id" {
  description = "EC2 instance ID for the Mattermost app server. Consumed by Ansible inventory."
  value       = aws_instance.mattermost.id
}

output "uploads_bucket" {
  description = "S3 bucket for Mattermost file uploads."
  value       = aws_s3_bucket.uploads.id
}

output "kms_key_arn" {
  description = "KMS key encrypting RDS, S3, and EBS for this stack."
  value       = aws_kms_key.mattermost.arn
}
