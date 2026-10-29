# ============================================================================
# COGNITO MODULE - OUTPUTS
# ============================================================================

data "aws_region" "current" {}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.this.endpoint
}

output "client_id" {
  description = "App Client ID (for frontend)"
  value       = aws_cognito_user_pool_client.this.id
}

output "jwt_issuer" {
  description = "JWT Issuer URL (for API Gateway)"
  value       = "https://cognito-idp.${data.aws_region.current.id}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}
