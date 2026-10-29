# ============================================================================
# LAMBDA FUNCTION MODULE - OUTPUTS
# ============================================================================

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Lambda invocation ARN (for API Gateway)"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "IAM execution role ARN"
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "IAM execution role name"
  value       = aws_iam_role.lambda.name
}

output "role_id" {
  description = "IAM execution role ID"
  value       = aws_iam_role.lambda.id
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}
