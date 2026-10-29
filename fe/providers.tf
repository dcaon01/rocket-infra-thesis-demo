# ============================================================================
# TERRAFORM PROVIDERS CONFIGURATION - ROCKET FRONTEND INFRASTRUCTURE
# ============================================================================

provider "aws" {
  region  = var.region
  profile = var.use_aws_profile ? try(lookup(var.aws_profiles, terraform.workspace, "default"), "default") : null

  allowed_account_ids = [lookup(var.aws_accounts, terraform.workspace, var.aws_accounts.dev)]

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "terraform"
      Repository  = "rocket-infra"
      Component   = "frontend"
    }
  }
}
