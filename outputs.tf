# ==============================================================
# outputs.tf
# Ausgabewerte, die Terraform nach `apply` anzeigt.
# Nützlich für:
#   - Ressourcendetails ohne AWS-Konsole einsehen
#   - Werte zwischen Terraform-Modulen weitergeben
#   - Skripting und Automatisierung
# ==============================================================


# ==============================================================
# EC2-INSTANZ-AUSGABEN
# Da wir `count` verwendet haben, sind dies Listen (eine pro Instanz).
# Beispiel: ["3.72.1.10", "18.185.2.44"]
# ==============================================================

output "instanz_ids" {
  description = "Liste der EC2-Instanz-IDs (für AWS-CLI-Befehle verwendbar)"
  value       = aws_instance.web[*].id
}

output "instanz_oeffentliche_ips" {
  description = "Liste der öffentlichen IP-Adressen aller EC2-Instanzen"
  value       = aws_instance.web[*].public_ip
}

output "instanz_oeffentliche_dns" {
  description = "Liste der öffentlichen DNS-Namen aller EC2-Instanzen"
  value       = aws_instance.web[*].public_dns
}

output "instanz_tags" {
  description = "Liste der Tag-Maps aller EC2-Instanzen (zur Überprüfung)"
  value       = aws_instance.web[*].tags
}

output "verwendetes_ami" {
  description = "ID und Name des automatisch gewählten Amazon Linux 2 AMI"
  value = {
    id   = data.aws_ami.amazon_linux.id
    name = data.aws_ami.amazon_linux.name
  }
}


# ==============================================================
# SECURITY-GROUP-AUSGABE
# ==============================================================

output "security_group_id" {
  description = "ID der Security Group, die den EC2-Instanzen zugeordnet ist"
  value       = aws_security_group.web_sg.id
}


# ==============================================================
# S3-BUCKET-AUSGABEN
# ==============================================================

output "s3_bucket_name" {
  description = "Name des erstellten S3-Buckets"
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  description = "ARN (Amazon Resource Name) des S3-Buckets — wird für IAM-Richtlinien benötigt"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_region" {
  description = "AWS-Region, in der der S3-Bucket erstellt wurde"
  value       = aws_s3_bucket.main.region
}


# ==============================================================
# ZUSAMMENFASSUNG
# Kombinierte Ausgabe mit den wichtigsten Informationen auf einen Blick.
# Wird nach `terraform apply` übersichtlich angezeigt.
# ==============================================================

output "bereitstellungs_zusammenfassung" {
  description = "Schnelle Übersicht der bereitgestellten Infrastruktur"
  value = {
    projekt          = var.project_name
    umgebung         = var.environment
    region           = var.aws_region
    instanz_anzahl   = var.instance_count
    instanz_typ      = var.aws_instance_type
    oeffentliche_ips = aws_instance.web[*].public_ip
    s3_bucket        = aws_s3_bucket.main.bucket
    security_group   = aws_security_group.web_sg.name
    ami_id           = data.aws_ami.amazon_linux.id
  }
}
