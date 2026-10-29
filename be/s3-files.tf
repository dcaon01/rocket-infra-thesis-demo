# ============================================================================
# S3 ARCHIVE BUCKET - ROCKET USER UPLOADS
# ============================================================================
# Stores user-uploaded files:
# - User profile pictures (avatars)
# - Contract PDFs
# - Product images
# - General attachments
#
# S3 event notifications configured separately in s3-events.tf
# ============================================================================

module "s3_files" {
  source = "../shared/modules/s3-storage"

  bucket_name = "${local.name_prefix}-archive"

  # CORS for browser uploads via presigned URLs
  enable_cors          = true
  cors_allowed_origins = lookup(local.cors_origins, local.environment, local.cors_origins.dev)
  cors_allowed_methods = ["GET", "PUT", "POST", "DELETE"]
  cors_allowed_headers = ["*"]
  cors_max_age_seconds = 3600

  # No versioning (to save costs), block public access
  enable_versioning   = false
  block_public_access = true

  # Lifecycle rules - archive old files
  lifecycle_rules = [
    {
      id                       = "archive-old-contracts"
      prefix                   = "contracts/"
      enabled                  = true
      transition_days          = 365
      transition_storage_class = "GLACIER"
    },
    {
      id              = "delete-old-temp-files"
      prefix          = "temp/"
      enabled         = true
      expiration_days = 7
    }
  ]

  # Cleanup incomplete uploads
  abort_incomplete_multipart_days = 7

  # Note: S3 event notifications configured separately in s3-events.tf
  # to avoid circular dependencies (same pattern as o2-infra)
  enable_sns_notifications = false

  tags = local.common_tags
}
