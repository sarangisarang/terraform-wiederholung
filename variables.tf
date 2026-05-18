# ==============================================================
# variables.tf
# All input variables for the terraform-wiederholung project.
# Values can be overridden with:
#   terraform apply -var="variable_name=value"
# or via a terraform.tfvars file.
# ==============================================================

# ---------------------------------------------------------------
# AWS Region
# ---------------------------------------------------------------
variable "aws_region" {
  description = "The AWS region where all resources will be created."
  type        = string
  default     = "eu-central-1"
}

# ---------------------------------------------------------------
# EC2 Instance Type
# ---------------------------------------------------------------
variable "aws_instance_type" {
  description = "EC2 instance type. Can be overridden at apply time."
  type        = string
  default     = "t2.micro" # Free-tier eligible
}

# ---------------------------------------------------------------
# AMI ID (Amazon Machine Image)
# This is the Amazon Linux 2 AMI for eu-central-1.
# Always verify the latest AMI in the AWS Console for your region.
# ---------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID to use for EC2 instances. Must match the selected region."
  type        = string
  default     = "ami-0a261c0e5f51090b1" # Amazon Linux 2, eu-central-1
}

# ---------------------------------------------------------------
# Number of EC2 instances to create (used with count)
# ---------------------------------------------------------------
variable "instance_count" {
  description = "How many EC2 instances to create."
  type        = number
  default     = 2
}

# ---------------------------------------------------------------
# Project metadata (used for Tags)
# ---------------------------------------------------------------
variable "project_name" {
  description = "Name tag for all resources. Helps identify resources in AWS Console."
  type        = string
  default     = "terraform-wiederholung"
}

variable "environment" {
  description = "Environment label, e.g. dev, staging, prod."
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------
# S3 Bucket Name
# S3 bucket names must be globally unique across ALL AWS accounts.
# Add a unique suffix (e.g. your name or timestamp) to avoid conflicts.
# ---------------------------------------------------------------
variable "s3_bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string
  default     = "terraform-wiederholung-bucket-guapa-2024"
}
