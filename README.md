# terraform-wiederholung

AWS-Infrastruktur als Code, mit einer GitHub-Actions-Pipeline drumherum: `plan` als
Vorschau in jedem Pull Request, `apply` und `destroy` nur manuell und bestätigt.

Übungsprojekt — bewusst klein gehalten, aber mit dem Workflow, den man auch produktiv fahren würde.

![Terraform](https://img.shields.io/badge/Terraform-HCL-7b42bc)
![AWS](https://img.shields.io/badge/AWS-EC2_·_S3-ff9900)
![CI](https://img.shields.io/badge/GitHub_Actions-plan_·_apply_·_destroy-2088ff)

---

## Was provisioniert wird

| Ressource | Details |
| --- | --- |
| **EC2** | Amazon Linux (AMI per `data`-Lookup, nicht hardcodiert), Anzahl und Instanztyp über Variablen |
| **Security Group** | SSH nur aus einem konfigurierbaren CIDR, HTTP öffentlich, ausgehend offen |
| **S3 Bucket** | mit `ownership_controls` und `public_access_block` — nicht-öffentlich per Default |

Alles über `variables.tf` parametrisiert (Region, Instanztyp, Anzahl, Key-Name, erlaubtes
SSH-CIDR, Projektname, Environment, Bucket-Name). `outputs.tf` gibt Instanz-IDs, öffentliche IPs
und DNS-Namen, Security-Group-ID, Bucket-ARN und eine zusammenfassende Übersicht zurück.

Zwei bewusste Entscheidungen:

- **Das AMI wird gesucht, nicht festgeschrieben.** Ein hardcodierter AMI-Wert ist regionsgebunden
  und veraltet schweigend; der `data`-Lookup bleibt in jeder Region gültig.
- **SSH ist auf ein CIDR beschränkt, HTTP nicht.** Der Unterschied ist Absicht: Port 80 gehört ins
  Internet, Port 22 nicht.

---

## Die Pipeline

| Workflow | Auslöser | Zweck |
| --- | --- | --- |
| **Terraform Plan** | Pull Request auf `main` | Vorschau der Änderungen, **Plan-Output als PR-Kommentar** |
| **Terraform Apply** | manuell (`workflow_dispatch`) | Änderungen ausrollen |
| **Terraform Destroy** | manuell, mit **Pflicht-Bestätigungsfeld** | Infrastruktur abbauen |

Der Punkt der Aufteilung: Der Plan läuft automatisch, damit niemand blind merged — die
Änderungen stehen im PR, bevor sie existieren. Was tatsächlich Geld kostet oder Dinge löscht,
läuft ausschließlich auf ausdrückliche Auslösung, und `destroy` verlangt zusätzlich eine getippte
Bestätigung.

Benötigte Repository-Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
optional `SLACK_WEBHOOK_URL` für Benachrichtigungen.

---

## Lokal ausführen

```bash
terraform init
terraform plan  -var="key_name=<dein-key>" -var="ssh_allowed_cidr=<deine-ip>/32"
terraform apply
```

`terraform destroy` räumt alles wieder ab.

---

© 2026 Beka Kikalishvili.
