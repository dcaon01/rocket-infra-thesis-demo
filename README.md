# ROCKET INFRA

## Utilizzo
1. Installare `aws-cli`.
2. Poi aprire prompt dei comandi e configurare `aws-cli` con `aws configure`.
3. Una volta installato e configurato, settare i profili in questo modo nel file `credentials` che trovi nella cartella `aws`:

```
[default]
aws_access_key_id = test
aws_secret_access_key = test
[nome-profilo]
aws_access_key_id = effettiva_access_key
aws_secret_access_key = effettivo_secret
```
Le informazioni del profilo si trovano nello IAM User creato tramite consolle. In ogni caso, questo farà in modo di poter switchare tra profili.

3. Prima di avviare una sessione di terraform, aprire il prompt dei comandi, o il cmd o la powershell che sia, e settare una variabile d'ambiente temporanea. In Windows, da cmd: 

```
set AWS_PROFILE=nome-profilo
```

4. Eseguire i comandi Terraform muovendosi all'intetrno della cartella contenente l'infrastruttura che si vuole tirare su.

## Template
L'infra segue un template con al seguente struttura:
- `backend-configs`: contiene le configurazioni generate dal terraform apply di bootstrap.
- `be`: contiene l'infrastruttura e i file di configurazione di terraform del backend di Rocket.
- `fe`: contiene l'infrastruttura e i file di configurazione di terraform del frontend idi Rocket.
- `bootstrap`: contiene i file terraform per creare i bucket s3 e le tabelle dynamo per mantenere lo stato di terraform in remoto e per generare i backend-configs.
- `shared`: contiene i moduli comuni alle altre cartelle.

## Ordine di esecuzione
Per prima cosa bisogna eseguire `bootstrap`. Successivamente si possono tirare su le infrastrutture a backend e frontend. E' importante commentare `module "terraform_state_backend"` dentro il main.tf in bootstrap succesivamente alla sua esecuzione per sicurezza.

## Deploy Lambda: placeholder vs S3

Le Lambda functions hanno due modalità di package source: `placeholder` e `s3`.

### Perché serve il placeholder (chicken-and-egg problem)

Quando si crea l'infrastruttura da zero con `terraform apply`, le Lambda hanno bisogno di un pacchetto per essere create. Ma a quel punto la CI/CD non ha ancora mai girato, quindi non esiste nessuno zip su S3 a cui puntare.

Il problema è circolare:
1. La Lambda vuole un file zip su S3 per essere creata
2. La CI/CD carica lo zip su S3 e poi aggiorna la Lambda via Terraform
3. Ma la CI/CD ha bisogno che l'infrastruttura (bucket S3, Lambda, IAM roles) esista già

Per rompere il cerchio si usa `package_source = "placeholder"`: Terraform crea la Lambda con un pacchetto fittizio locale, permettendo alla CI/CD di avere tutta l'infrastruttura pronta al primo giro.

### Quando passare a S3

Una volta che l'infrastruttura è stata creata con il placeholder e la CI/CD è configurata, si cambia a:

```hcl
package_source = "s3"
s3_bucket      = aws_s3_bucket.lambda_packages.id
s3_key         = "${local.environment}/${local.lambda_package_version}/core.zip"
```

Non serve fare `terraform apply` manualmente dopo questo cambio. La CI/CD gestisce tutto autonomamente:
1. **Build**: compila il codice e carica lo zip su `s3://{bucket}/{env}/{commit-sha}/{service}.zip`
2. **Plan**: esegue `terraform plan -var="lambda_package_version={commit-sha}"` e rileva il cambio di `s3_key`
3. **Apply**: aggiorna la Lambda per puntare al nuovo pacchetto S3

Basta pushare il cambio di configurazione su `rocket-infra` e lanciare la pipeline su `rocket-be`. Il plan vedrà la transizione da placeholder a S3 e l'apply la applicherà.