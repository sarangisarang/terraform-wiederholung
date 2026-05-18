# ==============================================================
# main.tf
# Core infrastructure definition for terraform-wiederholung.
#
# Resources created:
#   1. AWS Provider configuration
#   2. Security Group (SSH + HTTP)
#   3. EC2 Instances (multiple, via count)
#   4. S3 Bucket
# ==============================================================


# ==============================================================
# PROVIDER BLOCK
# Tells Terraform which cloud provider to use and in which region.
# All variables come from variables.tf.
# ==============================================================
provider "aws" {
  region = var.aws_region
}


# ==============================================================
# SECURITY GROUP
# A Security Group is a virtual firewall that controls inbound
# and outbound traffic for your EC2 instances.
#
# We open:
#   - Port 22  (SSH)  → for remote terminal access
#   - Port 80  (HTTP) → for web traffic
#   - All outbound traffic is allowed (standard practice)
# ==============================================================
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Security Group for ${var.project_name} EC2 instances"

  # --- Inbound: Allow SSH from anywhere (Port 22) ---
  # WARNING: In production, restrict this to your own IP!
  # Example for your own IP: cidr_blocks = ["YOUR_IP/32"]
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- Inbound: Allow HTTP from anywhere (Port 80) ---
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- Outbound: Allow all outbound traffic ---
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means ALL protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags help identify and organize resources in the AWS Console
  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


# ==============================================================
# EC2 INSTANCES
# We use `count` to create multiple instances from one block.
#
# count.index → 0, 1, 2, ... (used for unique naming)
#
# Each instance:
#   - Uses the AMI and instance type from variables.tf
#   - Gets attached to our Security Group above
#   - Gets unique Name, Project, Environment, and Instance tags
# ==============================================================
resource "aws_instance" "web" {
  count         = var.instance_count # Creates N instances
  ami           = var.ami_id
  instance_type = var.aws_instance_type

  # Attach the Security Group we defined above
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Tags for each instance — count.index makes the name unique
  tags = {
    Name        = "${var.project_name}-instance-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    Instance    = "instance-${count.index + 1}"
  }
}


# ==============================================================
# S3 BUCKET
# S3 is AWS object storage — like a folder in the cloud.
# Bucket names must be globally unique across all AWS accounts!
#
# We also add:
#   - Ownership controls (best practice since 2023)
#   - A private ACL (bucket is not publicly accessible)
# ==============================================================
resource "aws_s3_bucket" "main" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Project     = var.project_name
    Environment = var.environment
  }
}

# Ownership controls — recommended since AWS changed default settings
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block all public access — important for security
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
