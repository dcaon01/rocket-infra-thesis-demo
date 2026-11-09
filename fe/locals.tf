# ============================================================================
# LOCAL VALUES - ROCKET FRONTEND INFRASTRUCTURE
# ============================================================================

locals {
  # Environment derived from workspace
  environment = terraform.workspace

  # Environment-specific configurations
  env_config = {
    dev = {
      # CloudFront
      price_class = "PriceClass_100" # US, Europe

      # S3
      versioning_enabled = false

      # Performance
      compress = true
    }

    prod = {
      # CloudFront
      price_class = "PriceClass_All" # Global

      # S3
      versioning_enabled = true

      # Performance
      compress = true
    }
  }

  # Current environment configuration
  current_env = lookup(local.env_config, local.environment, local.env_config.dev)

  # Resource naming
  name_prefix = "${var.project_name}-${local.environment}"

  # Domain: combine subdomain + domain_name
  full_domain = var.domain_name != "" ? "${var.subdomain != "" ? "${var.subdomain}." : ""}${var.domain_name}" : ""

  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "rocket-infra"
    Component   = "frontend"
  }
}
