# ============================================================================
# PROVIDERS CONFIGURATION - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================

# AWS Provider with multi-account support
provider "aws" {
  region = var.region

  # Use profile only when use_aws_profile is true (local development)
  # In CI/CD, AWS credentials come from OIDC and profile should be null
  profile = var.use_aws_profile ? try(lookup(var.aws_profiles, terraform.workspace, "default"), "default") : null

  # Security: Only allow deployment to expected account
  allowed_account_ids = [lookup(var.aws_accounts, terraform.workspace, var.aws_accounts.dev)]

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "terraform"
      Repository  = "rocket-infra"
    }
  }
}

# Validation: Ensure we're deploying to the correct AWS account
resource "null_resource" "account_validation" {
  lifecycle {
    precondition {
      condition     = local.current_account_id == local.expected_account_id
      error_message = "Deploying to wrong AWS account! Expected: ${local.expected_account_id}, Got: ${local.current_account_id}"
    }
  }
}
