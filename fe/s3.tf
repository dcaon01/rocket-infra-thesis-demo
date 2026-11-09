# ============================================================================
# S3 STATIC HOSTING - ROCKET FRONTEND
# ============================================================================

# S3 Bucket for Frontend Static Files
module "frontend_hosting" {
  source = "../shared/modules/s3-frontend"

  # Basic Configuration
  name_prefix = local.name_prefix
  environment = local.environment

  # Bucket Configuration
  bucket_name        = "${local.name_prefix}-frontend"
  versioning_enabled = local.current_env.versioning_enabled

  # Security Configuration (Private bucket for CloudFront OAC)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.common_tags
}

# S3 Bucket Policy for CloudFront Origin Access Control (OAC)
# Created separately to avoid circular dependency between S3 and CloudFront
resource "aws_s3_bucket_policy" "frontend_cloudfront_policy" {
  bucket     = module.frontend_hosting.bucket_id
  depends_on = [module.frontend_hosting, module.frontend_cdn]

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.frontend_hosting.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.frontend_cdn.distribution_arn
          }
        }
      }
    ]
  })
}
