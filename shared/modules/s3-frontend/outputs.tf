# ============================================================================
# S3 FRONTEND STATIC HOSTING MODULE OUTPUTS
# ============================================================================

# S3 Bucket Information
output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

# Website Configuration
output "website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "website_domain" {
  description = "Domain of the website endpoint"
  value       = aws_s3_bucket_website_configuration.frontend.website_domain
}

# Security Information
output "bucket_public_access_block_id" {
  description = "ID of the S3 bucket public access block"
  value       = aws_s3_bucket_public_access_block.frontend.id
}
