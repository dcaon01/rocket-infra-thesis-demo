# ============================================================================
# OUTPUTS - ROCKET FRONTEND INFRASTRUCTURE
# ============================================================================

# General
output "environment" {
  description = "Current environment"
  value       = local.environment
}

output "aws_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.id
}

# GitHub OIDC
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions frontend deployment"
  value       = module.frontend_github_oidc.role_arn
}

output "github_actions_role_name" {
  description = "IAM role name for GitHub Actions frontend deployment"
  value       = module.frontend_github_oidc.role_name
}

# S3 Frontend Bucket
output "frontend_bucket_name" {
  description = "S3 bucket name for frontend static files"
  value       = module.frontend_hosting.bucket_name
}

output "frontend_bucket_arn" {
  description = "S3 bucket ARN for frontend static files"
  value       = module.frontend_hosting.bucket_arn
}

output "frontend_bucket_id" {
  description = "S3 bucket ID for frontend static files"
  value       = module.frontend_hosting.bucket_id
}

output "frontend_website_endpoint" {
  description = "S3 website endpoint for frontend"
  value       = module.frontend_hosting.website_endpoint
}

# CloudFront
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.frontend_cdn.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.frontend_cdn.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = module.frontend_cdn.distribution_arn
}

output "cloudfront_oac_arn" {
  description = "CloudFront Origin Access Control ARN"
  value       = module.frontend_cdn.oac_arn
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = module.frontend_cdn.cloudfront_url
}
