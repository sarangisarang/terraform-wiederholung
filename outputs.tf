# ==============================================================
# outputs.tf
# Outputs are values Terraform prints after `apply` completes.
# They are useful for:
#   - Seeing resource details without opening the AWS Console
#   - Passing values between Terraform modules
#   - Scripting and automation
# ==============================================================


# ==============================================================
# EC2 INSTANCE OUTPUTS
# Because we used `count`, these return lists (one per instance).
# Example: ["3.72.1.10", "18.185.2.44"]
# ==============================================================

output "instance_ids" {
  description = "List of EC2 instance IDs (use these in AWS CLI commands)"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of public IP addresses for all EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_public_dns" {
  description = "List of public DNS names for all EC2 instances"
  value       = aws_instance.web[*].public_dns
}

output "instance_tags" {
  description = "List of tag maps for all EC2 instances (useful for verification)"
  value       = aws_instance.web[*].tags
}


# ==============================================================
# SECURITY GROUP OUTPUT
# ==============================================================

output "security_group_id" {
  description = "ID of the Security Group attached to the EC2 instances"
  value       = aws_security_group.web_sg.id
}


# ==============================================================
# S3 BUCKET OUTPUTS
# ==============================================================

output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  description = "ARN (Amazon Resource Name) of the S3 bucket — needed for IAM policies"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_region" {
  description = "The AWS region where the S3 bucket was created"
  value       = aws_s3_bucket.main.region
}


# ==============================================================
# SUMMARY OUTPUT
# A combined output block showing the most important info at once.
# This is printed cleanly after `terraform apply` finishes.
# ==============================================================

output "deployment_summary" {
  description = "Quick summary of the deployed infrastructure"
  value = {
    project        = var.project_name
    environment    = var.environment
    region         = var.aws_region
    instance_count = var.instance_count
    instance_type  = var.aws_instance_type
    public_ips     = aws_instance.web[*].public_ip
    s3_bucket      = aws_s3_bucket.main.bucket
    security_group = aws_security_group.web_sg.name
  }
}
