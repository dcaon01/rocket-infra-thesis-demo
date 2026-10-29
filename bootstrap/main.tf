# =============================================================================
# bootstrap/main.tf - One-time setup for Terraform state backend
# =============================================================================
# Run this ONCE per AWS account to create the S3 bucket and DynamoDB table
# that store Terraform state.
#
# Usage:
#   cd bootstrap
#   terraform init
#   terraform apply
#
# After this, the backend-configs/*.tfbackend files can be used by be/ and fe/
# =============================================================================
# Provider configuration
provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# CloudPosse Label for consistent naming
module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = var.namespace
  environment = var.environment
  name        = var.project
  attributes  = [var.component]

  tags = {
    Project     = var.project
    Component   = var.component
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "terraform-state-backend"
  }
}

# CloudPosse Terraform State Backend
# Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
# Active for the first bootstrap of the demo account: comment it again once the state backends exist.

module "terraform_state_backend" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "1.7.1"

  namespace  = module.this.namespace
  stage      = module.this.environment
  name       = module.this.name
  attributes = module.this.attributes

  # Backend configuration file generation
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  # The files are already in backend-configs/, with the same names: no generation.
  terraform_backend_config_file_path = ""
  terraform_backend_config_file_name = "${var.environment}-${var.component}.tfbackend"

  # Security settings
  force_destroy               = var.environment == "dev" ? true : false
  prevent_unencrypted_uploads = true

  # Additional bucket settings
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = module.this.tags
}
