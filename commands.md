# Comandi Terraform - Rocket Infra

## Init

```bash
# Init backend (prima volta o cambio ambiente)
terraform init -backend-config=../backend-configs/dev-backend.tfbackend

# Cambiare ambiente (da dev a prod o viceversa)
terraform init -reconfigure -backend-config=../backend-configs/prod-backend.tfbackend

# Upgrade provider (se lo state è stato creato con versione più recente)
terraform init -upgrade -backend-config=../backend-configs/dev-backend.tfbackend
```

## Workspace

```bash
# Lista workspace disponibili
terraform workspace list

# Selezionare un workspace
terraform workspace select dev
terraform workspace select prod

# Creare un nuovo workspace
terraform workspace new <nome>

# Vedere workspace corrente
terraform workspace show
```

## Plan & Apply

```bash
# Plan (dev - usa terraform.tfvars automaticamente)
terraform plan

# Plan (prod - con tfvars specifico)
terraform plan -var-file=prod.tfvars

# Apply
terraform apply

# Apply prod
terraform apply -var-file=prod.tfvars

# Apply con auto-approve (senza conferma)
terraform apply -auto-approve

# Destroy (attenzione!)
terraform destroy
```

## State

```bash
# Lista risorse nello state
terraform state list

# Dettaglio di una risorsa
terraform state show <risorsa>

# Rimuovere una risorsa dallo state (senza distruggerla)
terraform state rm <risorsa>

# Import di una risorsa esistente
terraform import <risorsa> <id>

# Muovere/rinominare una risorsa nello state
terraform state mv <vecchio> <nuovo>
```

## Output

```bash
# Lista tutti gli output
terraform output

# Output specifico
terraform output <nome>

# Output in formato JSON
terraform output -json
```

## Validazione & Formato

```bash
# Validare la configurazione
terraform validate

# Formattare i file
terraform fmt

# Formattare ricorsivamente
terraform fmt -recursive
```

## Flusso tipico: deploy su dev

```bash
cd be
terraform init -backend-config=../backend-configs/dev-backend.tfbackend
terraform workspace select dev
terraform plan
terraform apply
```

## Flusso tipico: switch a prod

```bash
cd be
terraform init -reconfigure -backend-config=../backend-configs/prod-backend.tfbackend
terraform workspace select prod
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```
