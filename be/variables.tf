# ============================================================================
# GLOBAL VARIABLES - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================

variable "region" {
  description = <<-EOT
    AWS region where all backend infrastructure will be deployed.
    Used for Lambda functions, DynamoDB, API Gateway, and all related resources.
    Example: eu-south-1 (Milan), eu-north-1 (Stockholm), us-east-1 (N. Virginia)
  EOT
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  description = <<-EOT
    Project identifier used as prefix for all resource names.
    Final naming pattern: {project_name}-{environment}-{resource_type}
    Example: rocket-dev-lambda-core, rocket-prod-dynamodb-users
  EOT
  type        = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  # S3 bucket and Cognito domain names are global: the prefix keeps them apart from the ones of Keus.
  default     = "rocket-demo"
}

# ============================================================================
# MULTI-ACCOUNT CONFIGURATION
# ============================================================================

variable "aws_accounts" {
  description = <<-EOT
    Map of AWS account IDs for each environment (dev/prod).
    Used for account validation to prevent accidental deployment to wrong account.
    Must match the AWS account ID returned by `aws sts get-caller-identity`.

    Important: Update placeholder ID for prod before deploying to production environment.
    Validation error will occur if workspace account doesn't match actual account.
  EOT
  type        = map(string)
  default = {
    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    dev  = "397845934380"
    prod = "397845934380"
  }
}

variable "aws_profiles" {
  description = <<-EOT
    Map of AWS CLI profile names for each environment.
    Profiles should be configured in ~/.aws/config with appropriate credentials/roles.
    Only used when use_aws_profile = true (local development).
    CI/CD pipelines use OIDC instead (use_aws_profile = false).

    Example ~/.aws/config:
    [profile keus]
    region = eu-north-1
  EOT
  type        = map(string)
  default = {
    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    dev  = "damiano-sephiro"
    prod = "damiano-sephiro"
  }
}

# ============================================================================
# CI/CD CONFIGURATION
# ============================================================================

variable "use_aws_profile" {
  description = <<-EOT
    Toggle between AWS profile-based authentication (local) and OIDC-based authentication (CI/CD).

    • true:  Use AWS profiles from ~/.aws/config (for local development via terraform CLI)
    • false: Use GitHub OIDC provider for authentication (for GitHub Actions CI/CD pipelines)

    CI/CD pipelines should set this to false and rely on OIDC temporary credentials.
    This eliminates the need for long-lived AWS access keys in GitHub Secrets.
  EOT
  type        = bool
  default     = false
}

# ============================================================================
# LAMBDA CONFIGURATION
# ============================================================================

variable "lambda_runtime" {
  description = <<-EOT
    AWS Lambda runtime version for all backend microservices.
    Must match the Node.js version used in development and CI/CD.

    Supported values: nodejs18.x, nodejs20.x (recommended), nodejs22.x
    Default: nodejs20.x (LTS until April 2026, AWS support until end of 2026)

    Note: Ensure your package.json "engines" field matches this runtime version.
  EOT
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = <<-EOT
    Lambda function handler entrypoint.
    For AWS Lambda Web Adapter, this should be a shell script that starts your web app.

    Default: run.sh (bash script that executes 'npm start' to launch NestJS server)

    The Lambda package must include a run.sh file in the root:
    #!/bin/bash
    cd /var/task
    npm start

    Lambda Web Adapter then proxies HTTP requests to your app on the configured PORT.
  EOT
  type        = string
  default     = "run.sh"
}

variable "lambda_arch" {
  description = <<-EOT
    Lambda function architecture: x86_64 or arm64 (AWS Graviton2).

    • arm64: 20% better price/performance, recommended for most workloads
    • x86_64: Use only if dependencies require x86 architecture

    Default: arm64 (cost-optimized)

    Important: Lambda Web Adapter layer ARN must match this architecture.
    Current layer: LambdaAdapterLayerArm64 (for arm64 only)
  EOT
  type        = string
  default     = "arm64"
}

# Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
variable "lambda_placeholder" {
  description = <<-EOT
    Creates the Lambda functions with a placeholder package instead of the one on S3.
    Needed only by the first apply on an empty account, before the CI has uploaded any package.
  EOT
  type        = bool
  default     = false
}

variable "core_lambda_package_version" {
  description = <<-EOT
    Version identifier for Core Lambda deployment packages (e.g., git commit SHA).
    Used to construct S3 key: {environment}/{version}/{service}.zip

    Default: "latest" (not recommended for production)
  EOT
  type        = string
  default     = "latest"
}

variable "cognito_lambda_package_version" {
  description = <<-EOT
    Version identifier for Cognito Lambda deployment packages (e.g., git commit SHA).
    Used to construct S3 key: {environment}/{version}/{service}.zip

    Default: "latest" (not recommended for production)
  EOT
  type        = string
  default     = "latest"
}

variable "render_lambda_package_version" {
  description = <<-EOT
    Version identifier for Render Lambda deployment packages (e.g., git commit SHA).
    Used to construct S3 key: {environment}/{version}/{service}.zip

    Default: "latest" (not recommended for production)
  EOT
  type        = string
  default     = "latest"
}

# ============================================================================
# GITHUB CONFIGURATION
# ============================================================================

variable "github_org" {
  description = <<-EOT
    GitHub organization (or username) that owns the repository for OIDC federation.
    Used to construct the OIDC subject for trust relationship validation.

    Subject format: repo:{github_org}/{github_repo}:ref:refs/heads/main

    This restricts which GitHub repositories can assume AWS IAM roles via OIDC.
    Change this to your actual GitHub organization or personal username.

    Example: "keus-dev" for github.com/keus-dev/rocket-be
  EOT
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  type    = string
  default = "dcaon01"
}

variable "github_repo" {
  description = <<-EOT
    GitHub repository name for OIDC federation (without organization prefix).
    Combined with github_org to form the full repository identifier.

    Full repo path: github.com/{github_org}/{github_repo}

    Used in OIDC trust policy to restrict which repository can deploy infrastructure.
    Only GitHub Actions workflows from this specific repository can assume IAM roles.

    Example: "rocket-be" for the backend microservices repository
  EOT
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  type    = string
  default = "rocket-be-thesis-demo"
}

# ============================================================================
# APPLICATION SECRETS (provided via environment or tfvars)
# ============================================================================

variable "core_encryption_key" {
  description = <<-EOT
    Key for encrypting sensitive data in the application.
    Should be a secure random string (min 32 characters).

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_encryption_key
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain_name" {
  description = <<-EOT
    Domain name for the frontend application.
    Used in Lambda environment variables for redirects, email links, etc.

    Example: "rocket.example.com" for prod, "dev.rocket.example.com" for dev

    Demo mode: the CloudFront address of the frontend (dxxxx.cloudfront.net), known after its apply.
  EOT
  type        = string
  default     = "localhost:4200"
}

variable "core_hubspot_client_secret" {
  description = <<-EOT
    HubSpot client secret for API authentication.
    Get this from: HubSpot Developer Account > Apps > Your App > Auth > Client Secret

    Passed via CI/CD: GitHub Secrets → TF_VAR_hubspot_client_secret
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_hubspot_key" {
  description = <<-EOT
    HubSpot API key for authentication.
    Get this from: HubSpot Developer Account > API Key

    Passed via CI/CD: GitHub Secrets → TF_VAR_hubspot_key
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_hubspot_api_url" {
  description = <<-EOT
    Base URL of the HubSpot API.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_hubspot_api_url
  EOT
  type        = string
  default     = ""
}

variable "core_hubspot_products_pipeline_id" {
  description = <<-EOT
    HubSpot pipeline holding the deals of every product, told apart by their solution of
    interest.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_hubspot_products_pipeline_id
  EOT
  type        = string
  default     = ""
}

variable "core_keus_stripe_api_key" {
  description = <<-EOT
    Secret API key of the Stripe account of Keus, which bills the reseller subscription fees.
    Get this from: Stripe Dashboard (Keus account) > Developers > API keys

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_keus_stripe_api_key
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_keus_stripe_webhook_secret" {
  description = <<-EOT
    Signing secret of the webhook on the Stripe account of Keus (/rocket-core/webhooks/stripe/keus).
    Get this from: Stripe Dashboard (Keus account) > Developers > Webhooks > Signing secret

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_keus_stripe_webhook_secret
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_sibill_api_token" {
  description = <<-EOT
    Token of the Sibill company of Keus, which issues the electronic invoices. It also signs the Sibill webhooks.
    The dev workspace takes the token of the Sibill development company (app.dev.sibill.com), prod the production one:
    a production token in dev would send real invoices to the exchange system.
    Get this from: Sibill > Impostazioni > Integrazioni > Connettori

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_sibill_api_token
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_sibill_api_url" {
  description = <<-EOT
    Base URL of the Sibill integration API: the development one never reaches the exchange
    system.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_sibill_api_url
  EOT
  type        = string
  default     = ""
}

variable "core_sibill_company_id" {
  description = <<-EOT
    Identifier of the Sibill company of Keus, shown next to the token.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_sibill_company_id
  EOT
  type        = string
  default     = ""
}

variable "core_keus_stripe_tax_rate_id" {
  description = <<-EOT
    Tax rate applied to the reseller fee invoices on the Stripe account of Keus. Optional
    (an empty value means no tax rate is applied).

    Passed via CI/CD: GitHub Variables → TF_VAR_core_keus_stripe_tax_rate_id
  EOT
  type        = string
  default     = ""
}

variable "core_mixpanel_service_account_username" {
  description = <<-EOT
    Mixpanel service account username (read-only).
    Required: the core service throws an error at startup if missing.

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_mixpanel_service_account_username
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_mixpanel_service_account_secret" {
  description = <<-EOT
    Mixpanel service account secret (read-only).
    Required: the core service throws an error at startup if missing.

    Passed via CI/CD: GitHub Secrets → TF_VAR_core_mixpanel_service_account_secret
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_mixpanel_api_base_url" {
  description = <<-EOT
    Mixpanel Export API base URL (data residency). Optional: the core service
    defaults to https://data-eu.mixpanel.com in code, but we set it explicitly here.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_mixpanel_api_base_url
  EOT
  type        = string
  default     = "https://data-eu.mixpanel.com"
}

variable "core_intercom_access_token" {
  description = <<-EOT
    Access token of an internal Intercom app (read-only), for the support metrics.
    Optional: without it only the support metrics fail, when they are read.

    One per environment, since a token reads one workspace: dev reads the test workspace.

    Passed via CI/CD: GitHub Secrets ({ENV}_INTERCOM_ACCESS_TOKEN) → TF_VAR_core_intercom_access_token
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_intercom_api_url" {
  description = <<-EOT
    Intercom API base URL, by the region of the workspace. Optional: the core
    service defaults to https://api.intercom.io in code.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_intercom_api_url
  EOT
  type        = string
  default     = "https://api.intercom.io"
}

variable "core_sentry_auth_token" {
  description = <<-EOT
    Token of an internal Sentry integration (org:read, project:read, event:read), for the technical metrics.
    Optional: without it only the technical metrics fail, when they are read.

    One for both environments: a project holds dev and prod, and the core filters on SENTRY_ENVIRONMENT.

    Passed via CI/CD: GitHub Secrets (SENTRY_AUTH_TOKEN) → TF_VAR_core_sentry_auth_token
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "core_sentry_org" {
  description = <<-EOT
    Slug of the Sentry organization of Keus.

    Passed via CI/CD: GitHub Variables (SENTRY_ORG) → TF_VAR_core_sentry_org
  EOT
  type        = string
  default     = ""
}

variable "core_sentry_api_url" {
  description = <<-EOT
    Sentry API base URL, by the region of the organization. Optional: the core
    service defaults to https://de.sentry.io (EU) in code.

    Passed via CI/CD: GitHub Variables → TF_VAR_core_sentry_api_url
  EOT
  type        = string
  default     = "https://de.sentry.io"
}


# Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
variable "integrations_enabled" {
  description = <<-EOT
    Whether the core talks to the systems outside AWS: the products, Stripe, Sibill, HubSpot, Intercom, Mixpanel
    and Sentry. Set it to false for a demo account without them: the core answers for the products itself, charges
    nothing and reads the external metrics only from their stored records.

    Off in the demo, which has none of them.
  EOT
  type        = bool
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = false
}
