# ============================================================================
# INPUT VARIABLES - ROCKET FRONTEND INFRASTRUCTURE
# ============================================================================

# ============================================================================
# BASIC CONFIGURATION
# ============================================================================

variable "project_name" {
  description = <<-EOT
    Project identifier used as prefix for all frontend resource names.
    Final naming pattern: {project_name}-{environment}-frontend
  EOT
  type    = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  # S3 bucket and Cognito domain names are global: the prefix keeps them apart from the ones of Keus.
  default = "rocket-demo"
}

variable "region" {
  description = <<-EOT
    AWS region for S3 bucket creation.
    CloudFront is global, but the S3 origin bucket needs a specific region.
  EOT
  type    = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "eu-west-1"
}

# ============================================================================
# MULTI-ACCOUNT CONFIGURATION
# ============================================================================

variable "aws_accounts" {
  description = <<-EOT
    Map of AWS account IDs for each environment (dev/prod).
    Used for account validation to prevent accidental deployment to wrong account.
  EOT
  type = map(string)
  default = {
    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    dev  = "397845934380"
    prod = "397845934380"
  }
}

variable "aws_profiles" {
  description = <<-EOT
    Map of AWS CLI profile names for each environment.
    Only used when use_aws_profile = true (local development).
  EOT
  type = map(string)
  default = {
    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    dev  = "damiano-sephiro"
    prod = "damiano-sephiro"
  }
}

variable "use_aws_profile" {
  description = <<-EOT
    Toggle between AWS profile-based auth (local) and OIDC-based auth (CI/CD).
    CI/CD pipelines should set this to false and rely on OIDC temporary credentials.
  EOT
  type    = bool
  default = false
}

# ============================================================================
# DOMAIN CONFIGURATION
# ============================================================================

variable "domain_name" {
  description = <<-EOT
    Custom domain name for the frontend application (e.g., "rocket.example.com").
    Leave empty to use CloudFront's default domain (xxxxx.cloudfront.net).

    To enable custom domain:
    1. Set this variable to your domain
    2. Create ACM certificate in us-east-1 and set certificate_arn
    3. Create Route53 alias record pointing to CloudFront distribution
  EOT
  type    = string
  default = ""
}

variable "certificate_arn" {
  description = <<-EOT
    ARN of the ACM certificate for custom domain (must be in us-east-1 region).
    Required when domain_name is specified.
  EOT
  type    = string
  default = ""
}

variable "subdomain" {
  description = <<-EOT
    Subdomain prefix for the frontend application.
    Combined with domain_name to form full FQDN: {subdomain}.{domain_name}
    Leave empty to use root domain.
  EOT
  type    = string
  default = ""
}

# ============================================================================
# GITHUB CONFIGURATION
# ============================================================================

variable "github_org" {
  description = <<-EOT
    GitHub organization that owns the frontend repository.
    Used for OIDC federation to enable keyless deployments.
  EOT
  type    = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "dcaon01"
}

variable "github_repo" {
  description = <<-EOT
    GitHub frontend repository name (without organization prefix).
    Only GitHub Actions from this repository can deploy to S3 and invalidate CloudFront.
  EOT
  type    = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "rocket-fe-thesis-demo"
}
