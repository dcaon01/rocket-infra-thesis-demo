# ============================================================================
# CLOUDFRONT CDN - ROCKET FRONTEND
# ============================================================================

# CloudFront Distribution with Origin Access Control (OAC)
module "frontend_cdn" {
  source = "../shared/modules/cloudfront-cdn"

  # Basic Configuration
  name_prefix = local.name_prefix
  environment = local.environment

  # S3 Origin Configuration
  s3_bucket_name                 = module.frontend_hosting.bucket_name
  s3_bucket_regional_domain_name = module.frontend_hosting.bucket_regional_domain_name

  # CloudFront Configuration
  price_class = local.current_env.price_class
  compress    = local.current_env.compress

  # Custom domain configuration
  domain_name     = local.full_domain
  certificate_arn = var.certificate_arn

  tags = local.common_tags
}
