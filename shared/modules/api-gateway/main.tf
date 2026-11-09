# ============================================================================
# API GATEWAY MODULE - HTTP API V2
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8"
    }
  }
}

# ----------------------------------------------------------------------------
# HTTP API
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.name
  protocol_type = "HTTP"
  description   = var.description

  dynamic "cors_configuration" {
    for_each = length(var.cors_allow_origins) > 0 ? [1] : []
    content {
      allow_origins     = var.cors_allow_origins
      allow_methods     = var.cors_allow_methods
      allow_headers     = var.cors_allow_headers
      expose_headers    = ["Content-Length", "Content-Type"]
      max_age           = var.cors_max_age
      allow_credentials = var.cors_allow_credentials
    }
  }

  tags = var.tags
}

# ----------------------------------------------------------------------------
# STAGE
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      errorMessage     = "$context.error.message"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  tags = var.tags
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ----------------------------------------------------------------------------
# JWT AUTHORIZER (Cognito)
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  count = var.enable_jwt_authorizer && var.jwt_issuer != "" ? 1 : 0

  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "cognito-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.jwt_issuer
    audience = var.jwt_audience
  }
}

# ----------------------------------------------------------------------------
# INTEGRATIONS
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = var.integrations

  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ----------------------------------------------------------------------------
# LAMBDA PERMISSIONS
# ----------------------------------------------------------------------------

resource "aws_lambda_permission" "lambda_invoke" {
  for_each = var.integrations

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = split(":", each.value.lambda_arn)[6]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# ----------------------------------------------------------------------------
# ROUTES
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_route" "api_routes" {
  for_each = { for idx, route in var.routes : "${route.route_key}" => route }

  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.value.integration_id].id}"

  authorization_type = each.value.require_auth && var.enable_jwt_authorizer ? "JWT" : "NONE"
  authorizer_id      = each.value.require_auth && var.enable_jwt_authorizer && length(aws_apigatewayv2_authorizer.cognito_jwt) > 0 ? aws_apigatewayv2_authorizer.cognito_jwt[0].id : null
}
