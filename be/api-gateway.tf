# ============================================================================
# API GATEWAY - ROCKET HTTP API
# ============================================================================
# Routes HTTP requests to Lambda functions.
# JWT tokens validated against Cognito User Pool.
#
# Protected routes: require valid JWT token
# Public routes: health checks, webhooks (Stripe, HubSpot)
# ============================================================================

module "api_gateway" {
  source = "../shared/modules/api-gateway"

  # Basic configuration
  name        = "${local.name_prefix}-api"
  description = "Rocket Backend API"
  stage_name  = "$default"

  # CORS - allow frontend origins
  cors_allow_origins     = lookup(local.cors_origins, local.environment, local.cors_origins.dev)
  cors_allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
  cors_allow_headers     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
  cors_max_age           = 3600
  cors_allow_credentials = true

  # JWT authorization - validate tokens from Cognito
  enable_jwt_authorizer = true
  jwt_issuer            = module.cognito.jwt_issuer
  jwt_audience          = [module.cognito.client_id]

  # Rate limiting
  throttling_burst_limit = local.config.api_throttling_burst
  throttling_rate_limit  = local.config.api_throttling_rate

  # Logging
  log_retention_days = local.config.log_retention_days

  # Lambda integrations
  integrations = {
    core = {
      lambda_invoke_arn = module.lambda_core.invoke_arn
      lambda_arn        = module.lambda_core.function_arn
    }
    cognito = {
      lambda_invoke_arn = module.lambda_cognito.invoke_arn
      lambda_arn        = module.lambda_cognito.function_arn
    }
  }

  # Route definitions
  routes = [
    # -------------------------------------------------------------------------
    # CORE API ROUTES (authenticated)
    # Using explicit methods instead of ANY to avoid catching OPTIONS preflight
    # -------------------------------------------------------------------------
    { route_key = "GET /rocket-core/{proxy+}", integration_id = "core", require_auth = true },
    { route_key = "POST /rocket-core/{proxy+}", integration_id = "core", require_auth = true },
    { route_key = "PUT /rocket-core/{proxy+}", integration_id = "core", require_auth = true },
    { route_key = "PATCH /rocket-core/{proxy+}", integration_id = "core", require_auth = true },
    { route_key = "DELETE /rocket-core/{proxy+}", integration_id = "core", require_auth = true },

    # Health check (public)
    { route_key = "GET /rocket-core/health", integration_id = "core", require_auth = false },

    # -------------------------------------------------------------------------
    # COGNITO API ROUTES (authenticated)
    # -------------------------------------------------------------------------
    { route_key = "GET /rocket-cognito/{proxy+}", integration_id = "cognito", require_auth = true },
    { route_key = "POST /rocket-cognito/{proxy+}", integration_id = "cognito", require_auth = true },
    { route_key = "PUT /rocket-cognito/{proxy+}", integration_id = "cognito", require_auth = true },
    { route_key = "PATCH /rocket-cognito/{proxy+}", integration_id = "cognito", require_auth = true },
    { route_key = "DELETE /rocket-cognito/{proxy+}", integration_id = "cognito", require_auth = true },

    # Health check (public)
    { route_key = "GET /rocket-cognito/health", integration_id = "cognito", require_auth = false },

    # -------------------------------------------------------------------------
    # WEBHOOKS (public - no auth)
    # -------------------------------------------------------------------------
    # Stripe webhook - payment events (per-product: /webhooks/stripe/{productId})
    { route_key = "POST /rocket-core/webhooks/stripe/{proxy+}", integration_id = "core", require_auth = false },

    # HubSpot webhook - CRM events
    { route_key = "POST /rocket-core/webhooks/hubspot", integration_id = "core", require_auth = false },

    # Sibill webhook - state of the electronic invoices at the exchange system (signed with the Sibill token)
    { route_key = "POST /rocket-core/webhooks/sibill", integration_id = "core", require_auth = false }
  ]

  tags = local.common_tags
}
