# ============================================================================
# LOCAL VALUES - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================

locals {
  # Environment derived from workspace
  environment = terraform.workspace

  # Current AWS account validation
  current_account_id  = data.aws_caller_identity.current.account_id
  expected_account_id = lookup(var.aws_accounts, local.environment, var.aws_accounts.dev)

  # ---------------------------------------------------------------------------
  # ENVIRONMENT-SPECIFIC CONFIGURATIONS
  # ---------------------------------------------------------------------------
  env_config = {
    dev = {
      # Lambda
      lambda_memory_size    = 256
      lambda_memory_core    = 512 # Core needs more memory
      lambda_memory_cognito = 256
      lambda_memory_render  = 512
      lambda_timeout        = 120
      log_retention_days    = 7

      # CloudWatch
      logs_retention_days = 7

      # S3 Storage
      lambda_packages_retention_days = 7
      app_files_retention_days       = 30

      # API Gateway
      api_throttling_burst = 100
      api_throttling_rate  = 50

      # EventBridge
      eventbridge_archive_days = 7

      # Costs optimization
      deletion_protection = false

      # Domain
      # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
      domain_name = var.domain_name

      # Mixpanel: only the events of this environment are read; the products send it as `environment`
      mixpanel_environment = "dev"

      # EventBridge - External products integration
      # Key = unique config name, product_id = productId for event matching
      # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
      # No products to reach: Rocket answers for them (DemoProductService).
      products_config         = {}
      product_sqs_writer_arns = []
    }

    prod = {
      # Lambda
      lambda_memory_size    = 512
      lambda_memory_core    = 1024 # Core needs more memory in prod
      lambda_memory_cognito = 512
      lambda_memory_render  = 512
      lambda_timeout        = 300
      log_retention_days    = 90

      # CloudWatch
      logs_retention_days = 90

      # S3 Storage
      lambda_packages_retention_days = 90
      app_files_retention_days       = 365

      # API Gateway
      api_throttling_burst = 500
      api_throttling_rate  = 200

      # EventBridge
      eventbridge_archive_days = 90

      # Full protection
      deletion_protection = true

      # Domain
      # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
      domain_name = var.domain_name

      # Mixpanel: empty reads every event, until the products of prod send `environment`
      mixpanel_environment = ""

      # EventBridge - External products integration
      # Key = unique config name, product_id = productId for event matching
      # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
      # No products to reach: Rocket answers for them (DemoProductService).
      products_config         = {}
      product_sqs_writer_arns = []
    }
  }

  # Current environment configuration (with shorthand alias)
  current_env = lookup(local.env_config, local.environment, local.env_config.dev)
  config      = local.current_env # Shorthand alias

  # ---------------------------------------------------------------------------
  # CORS ORIGINS BY ENVIRONMENT
  # ---------------------------------------------------------------------------
  cors_origins = {
    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    dev  = ["http://localhost:4200", "http://localhost:3000", "https://${local.config.domain_name}"]
    prod = ["https://${local.config.domain_name}"]
  }

  # ---------------------------------------------------------------------------
  # COGNITO CONFIGURATION BY ENVIRONMENT
  # ---------------------------------------------------------------------------
  cognito_config = {
    dev = {
      import_existing  = false
      existing_pool_id = null
      domain_prefix    = "${var.project_name}-dev-auth"
    }
    prod = {
      import_existing  = false
      existing_pool_id = null
      domain_prefix    = "${var.project_name}-prod-auth"
    }
  }

  current_cognito_config = lookup(local.cognito_config, local.environment, local.cognito_config.dev)

  # ---------------------------------------------------------------------------
  # EMAIL
  # ---------------------------------------------------------------------------
  # Rocket sends from noreply@ on the FE domain, signed by Keus. Templates and images live in
  # templates/email/ (see emails.tf).
  mail_dns_zone    = "keus.dev"
  mail_from_domain = "bounce.${local.config.domain_name}"
  mail_from        = "Keus <noreply@${local.config.domain_name}>"
  login_url        = "https://${local.config.domain_name}/login"

  # Read by the user pool and quoted in the invite email.
  temporary_password_validity_days = 7

  # ---------------------------------------------------------------------------
  # LAMBDA CONFIGURATION
  # ---------------------------------------------------------------------------
  core_lambda_package_version    = var.core_lambda_package_version
  cognito_lambda_package_version = var.cognito_lambda_package_version
  render_lambda_package_version  = var.render_lambda_package_version

  # Name of the render Lambda as plain text: core reads it without depending on module.lambda_render,
  # so a deploy of core alone (-target=module.lambda_core) does not pull the render Lambda in.
  render_function_name = "${local.name_prefix}-render"

  # Standard Lambda environment variables (shared across all functions)
  standard_lambda_env_vars = {
    NODE_ENV = local.environment
    # Project tag of the tables Dynamoose creates at boot, the same value as default_tags
    PROJECT_NAME            = var.project_name
    AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
    PORT                    = "3001"
  }

  # ---------------------------------------------------------------------------
  # ROCKET MICROSERVICES CONFIGURATION
  # ---------------------------------------------------------------------------
  # Rocket has 2 microservices: core and cognito
  rocket_services = {
    cognito = {
      port     = "3002"
      app_name = "rocket-cognito"
      needs_s3 = true # For profile images
    }
    core = {
      port     = "3003"
      app_name = "rocket-core"
      needs_s3 = true # For file uploads
    }
  }

  # ---------------------------------------------------------------------------
  # API GATEWAY CONFIGURATION
  # ---------------------------------------------------------------------------
  http_methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]

  # Lambda modules mapping for API Gateway
  lambda_modules = {
    "rocket-cognito" = {
      arn           = module.lambda_cognito.function_arn
      function_name = module.lambda_cognito.function_name
      invoke_arn    = module.lambda_cognito.invoke_arn
    }
    "rocket-core" = {
      arn           = module.lambda_core.function_arn
      function_name = module.lambda_core.function_name
      invoke_arn    = module.lambda_core.invoke_arn
    }
  }

  # ---------------------------------------------------------------------------
  # RESOURCE NAMING
  # ---------------------------------------------------------------------------
  name_prefix = "${var.project_name}-${local.environment}"

  # ---------------------------------------------------------------------------
  # COMMON TAGS
  # ---------------------------------------------------------------------------
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "rocket-infra"
  }
}
