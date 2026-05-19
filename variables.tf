# ==============================================================
# variables.tf
# Alle Eingabevariablen für das terraform-wiederholung-Projekt.
# Werte können überschrieben werden mit:
#   terraform apply -var="variablenname=wert"
# oder über eine terraform.tfvars-Datei.
# ==============================================================


# --------------------------------------------------------------
# AWS-Region
# --------------------------------------------------------------
variable "aws_region" {
  description = "Die AWS-Region, in der alle Ressourcen erstellt werden."
  type        = string
  default     = "eu-central-1"
}


# --------------------------------------------------------------
# EC2-Instanztyp
# --------------------------------------------------------------
variable "aws_instance_type" {
  description = "EC2-Instanztyp. Kann zur Laufzeit überschrieben werden."
  type        = string
  default     = "t2.micro" # Free-Tier geeignet
}


# --------------------------------------------------------------
# Anzahl der EC2-Instanzen (wird mit count verwendet)
# --------------------------------------------------------------
variable "instance_count" {
  description = "Wie viele EC2-Instanzen erstellt werden sollen."
  type        = number
  default     = 2
}


# --------------------------------------------------------------
# SSH Key-Pair Name
# Muss vorher in AWS erstellt werden (pro Region unterschiedlich).
# Erstellung per CLI:
#   aws ec2 create-key-pair --key-name <name> \
#     --query 'KeyMaterial' --output text > <name>.pem
#   chmod 400 <name>.pem
# --------------------------------------------------------------
variable "key_name" {
  description = "Name des AWS Key-Pairs für den SSH-Zugang zu den EC2-Instanzen."
  type        = string
}


# --------------------------------------------------------------
# Erlaubte IP-Adresse für SSH-Zugang (Port 22)
# Format: "x.x.x.x/32" für eine einzelne IP-Adresse.
# Eigene IP herausfinden: curl ifconfig.me
# NIEMALS "0.0.0.0/0" in Produktionsumgebungen verwenden!
# --------------------------------------------------------------
variable "ssh_allowed_cidr" {
  description = "CIDR-Block der erlaubten IP-Adresse für SSH (z.B. '203.0.113.5/32')."
  type        = string
}


# --------------------------------------------------------------
# Projekt-Metadaten (für Tags)
# --------------------------------------------------------------
variable "project_name" {
  description = "Name-Tag für alle Ressourcen. Hilft bei der Identifikation in der AWS-Konsole."
  type        = string
  default     = "terraform-wiederholung"
}

variable "environment" {
  description = "Umgebungsbezeichnung, z.B. dev, staging, prod."
  type        = string
  default     = "dev"
}


# --------------------------------------------------------------
# S3-Bucket-Name
# S3-Bucket-Namen müssen weltweit eindeutig sein (über ALLE AWS-Konten).
# Füge ein eindeutiges Suffix hinzu, um Konflikte zu vermeiden.
# --------------------------------------------------------------
variable "s3_bucket_name" {
  description = "Weltweit eindeutiger Name für den S3-Bucket."
  type        = string
  default     = "terraform-wiederholung-bucket-guapa-2024"
}
