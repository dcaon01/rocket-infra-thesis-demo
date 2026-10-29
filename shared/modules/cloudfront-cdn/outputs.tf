# ============================================================================
# CLOUDFRONT CDN MODULE OUTPUTS
# ============================================================================

# CloudFront Distribution Information
output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

# Origin Access Control Information
output "oac_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}

output "oac_arn" {
  description = "Origin Access Control ARN for S3 bucket policy"
  value       = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/${aws_cloudfront_origin_access_control.s3_oac.id}"
}

# Convenience URLs
output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : ""
}

# Data sources
data "aws_caller_identity" "current" {}
