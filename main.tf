# ==============================================================
# main.tf
# Haupt-Infrastrukturdatei für terraform-wiederholung.
#
# Erstellte Ressourcen:
#   1. AWS Provider-Konfiguration
#   2. Datenbeschaffung: aktuelles Amazon Linux 2 AMI
#   3. Security Group (SSH + HTTP)
#   4. EC2-Instanzen (mehrere via count)
#   5. S3-Bucket mit Zugriffskontrolle
# ==============================================================


# ==============================================================
# TERRAFORM-BLOCK
# Definiert das Remote Backend (S3 + DynamoDB) für die State-Datei.
#
# WICHTIG: Diese Ressourcen müssen VORHER manuell erstellt werden,
# bevor `terraform init` ausgeführt wird:
#   1. S3-Bucket für den State
#   2. DynamoDB-Tabelle für State-Locking (Attribut: LockID, Typ: S)
#
# Anleitung:
#   aws s3api create-bucket --bucket <dein-state-bucket> --region eu-central-1 \
#     --create-bucket-configuration LocationConstraint=eu-central-1
#   aws dynamodb create-table --table-name terraform-state-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST --region eu-central-1
# ==============================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-wiederholung-state-bucket"
    key          = "terraform-wiederholung/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true  # S3-natives Locking (ersetzt DynamoDB, ab Terraform 1.10)
    encrypt      = true
  }
}


# ==============================================================
# PROVIDER-BLOCK
# Gibt an, welcher Cloud-Anbieter verwendet wird und in welcher Region.
# ==============================================================
provider "aws" {
  region = var.aws_region
}


# ==============================================================
# AMI-DATENBESCHAFFUNG (Data Source)
# Sucht automatisch das aktuellste Amazon Linux 2 AMI für die
# gewählte Region. Dadurch wird eine veraltete hardcoded AMI-ID vermieden.
#
# Verwendung: data.aws_ami.amazon_linux.id
# ==============================================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # Nur offizielle Amazon-Images

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ==============================================================
# SECURITY GROUP
# Virtuelle Firewall für die EC2-Instanzen.
#
# Geöffnete Ports:
#   - Port 22  (SSH)  → nur für die erlaubte IP-Adresse (var.ssh_allowed_cidr)
#   - Port 80  (HTTP) → für alle (öffentliche Webseite)
#   - Ausgehender Datenverkehr: vollständig erlaubt (Standard)
# ==============================================================
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Security Group fuer ${var.project_name} EC2-Instanzen"

  # --- Eingehend: SSH nur von der erlaubten IP-Adresse ---
  # Sicherheitshinweis: Setze var.ssh_allowed_cidr auf deine eigene IP,
  # z.B. "203.0.113.5/32". Niemals "0.0.0.0/0" in Produktion verwenden!
  ingress {
    description = "SSH-Zugang - nur erlaubte IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # --- Eingehend: HTTP für alle ---
  ingress {
    description = "HTTP-Zugang - oeffentlich"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- Ausgehend: Gesamten Ausgangsverkehr erlauben ---
  egress {
    description = "Ausgehenden Datenverkehr erlauben"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 bedeutet ALLE Protokolle
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


# ==============================================================
# EC2-INSTANZEN
# Erstellt mehrere Instanzen über den `count`-Parameter.
#
# count.index → 0, 1, 2, ... (für eindeutige Benennung)
#
# Jede Instanz:
#   - Verwendet das aktuellste AMI (via Data Source, nicht hardcoded)
#   - Wird mit dem SSH-Key-Pair verbunden (var.key_name)
#   - Gehört zur oben definierten Security Group
# ==============================================================
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id # Automatisch aktuellstes AMI
  instance_type = var.aws_instance_type

  # SSH-Key-Pair für den Zugang zur Instanz
  # Muss vorher in der AWS-Konsole oder per CLI erstellt werden:
  #   aws ec2 create-key-pair --key-name <name> --query 'KeyMaterial' \
  #     --output text > <name>.pem
  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name        = "${var.project_name}-instanz-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    Instance    = "instanz-${count.index + 1}"
  }
}


# ==============================================================
# S3-BUCKET
# Objektspeicher in der Cloud. Bucket-Namen müssen weltweit eindeutig sein.
#
# Zusätzliche Ressourcen:
#   - Eigentumsregeln (seit 2023 empfohlen)
#   - Vollständige Sperrung des öffentlichen Zugriffs (Sicherheit)
# ==============================================================
resource "aws_s3_bucket" "main" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Project     = var.project_name
    Environment = var.environment
  }
}

# Eigentumsregeln — empfohlen seit der AWS-Standardänderung 2023
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Öffentlichen Zugriff vollständig sperren — wichtig für die Sicherheit
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
