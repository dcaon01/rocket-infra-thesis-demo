# =============================================================================
# API GATEWAY MODULE - OUTPUTS
# =============================================================================

output "api_id" {
  description = "API Gateway ID (unique identifier)"
  value       = aws_apigatewayv2_api.http_api.id
}

output "api_arn" {
  description = "API Gateway ARN (for IAM policies)"
  value       = aws_apigatewayv2_api.http_api.arn
}

output "api_endpoint" {
  description = "API Gateway base endpoint URL (without stage)"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "execution_arn" {
  description = "API Gateway execution ARN (for Lambda permissions)"
  value       = aws_apigatewayv2_api.http_api.execution_arn
}

output "stage_invoke_url" {
  description = "Full URL to call the API (includes stage). This is what clients use."
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "stage_id" {
  description = "Stage ID"
  value       = aws_apigatewayv2_stage.api_stage.id
}

output "authorizer_id" {
  description = "JWT Authorizer ID (null if not created)"
  value       = length(aws_apigatewayv2_authorizer.cognito_jwt) > 0 ? aws_apigatewayv2_authorizer.cognito_jwt[0].id : null
}

output "integration_ids" {
  description = "Map of integration IDs by key"
  value       = { for k, v in aws_apigatewayv2_integration.lambda_integrations : k => v.id }
}
