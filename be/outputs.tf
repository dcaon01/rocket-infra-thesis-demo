# ============================================================================
# OUTPUTS - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================
# These values are exported for:
# 1. Frontend app configuration
# 2. CI/CD pipeline configuration
# 3. Cross-stack references (fe/ terraform)
# 4. Manual debugging and monitoring
# ============================================================================

# ============================================================================
# API GATEWAY
# ============================================================================

output "api_gateway_url" {
  description = "API Gateway invocation URL (use this in frontend)"
  value       = module.api_gateway.stage_invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

# ============================================================================
# COGNITO
# ============================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (format: {region}_{id})"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID (use in frontend Amplify config)"
  value       = module.cognito.client_id
}

output "cognito_jwt_issuer" {
  description = "Cognito JWT Issuer URL (for token validation)"
  value       = module.cognito.jwt_issuer
}

# ============================================================================
# LAMBDA FUNCTIONS
# ============================================================================

output "lambda_core_function_name" {
  description = "Lambda Core function name"
  value       = module.lambda_core.function_name
}

output "lambda_core_function_arn" {
  description = "Lambda Core function ARN"
  value       = module.lambda_core.function_arn
}

output "lambda_cognito_function_name" {
  description = "Lambda Cognito function name"
  value       = module.lambda_cognito.function_name
}

output "lambda_cognito_function_arn" {
  description = "Lambda Cognito function ARN"
  value       = module.lambda_cognito.function_arn
}

output "lambda_packages_bucket" {
  description = "S3 bucket for Lambda deployment packages"
  value       = aws_s3_bucket.lambda_packages.id
}

# ============================================================================
# S3 FILES
# ============================================================================

output "s3_files_bucket" {
  description = "S3 bucket for user uploads (archive)"
  value       = module.s3_files.bucket_name
}

output "s3_files_bucket_arn" {
  description = "S3 archive bucket ARN (for IAM policies)"
  value       = module.s3_files.bucket_arn
}

# ============================================================================
# EVENTBRIDGE
# ============================================================================

output "eventbridge_bus_name" {
  description = "EventBridge bus name (for publishing events)"
  value       = aws_cloudwatch_event_bus.rocket.name
}

output "eventbridge_bus_arn" {
  description = "EventBridge bus ARN (for IAM policies)"
  value       = aws_cloudwatch_event_bus.rocket.arn
}

# ============================================================================
# SQS QUEUES
# ============================================================================

output "sqs_inbound_queue_url" {
  description = "SQS inbound queue URL (products send messages here)"
  value       = module.sqs_inbound.queue_url
}

output "sqs_inbound_queue_arn" {
  description = "SQS inbound queue ARN (for IAM policies)"
  value       = module.sqs_inbound.queue_arn
}

# ============================================================================
# GITHUB OIDC
# ============================================================================

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN (existing provider, shared with fe/ stack)"
  value       = module.github_oidc_ci.oidc_provider_arn
}

output "github_be_ci_role_arn" {
  description = "GitHub Actions role ARN for BE CI (build/upload)"
  value       = module.github_oidc_ci.role_arn
}

output "github_be_terraform_role_arn" {
  description = "GitHub Actions role ARN for BE Terraform"
  value       = module.github_oidc_terraform.role_arn
}

# ============================================================================
# ENVIRONMENT INFO
# ============================================================================

output "environment" {
  description = "Current environment (dev or prod)"
  value       = local.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
