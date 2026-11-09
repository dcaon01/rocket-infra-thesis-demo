# ============================================================================
# S3 STORAGE MODULE
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8"
    }
  }
}

# ----------------------------------------------------------------------------
# S3 BUCKET
# ----------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
  }
}

# ----------------------------------------------------------------------------
# CORS
# ----------------------------------------------------------------------------

resource "aws_s3_bucket_cors_configuration" "this" {
  count  = var.enable_cors && length(var.cors_allowed_origins) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = var.cors_max_age_seconds
  }
}

# ----------------------------------------------------------------------------
# LIFECYCLE
# ----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 || var.abort_incomplete_multipart_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transition_days", null) != null ? [1] : []
        content {
          days          = rule.value.transition_days
          storage_class = rule.value.transition_storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration_days", null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_days
    }
  }
}

# ----------------------------------------------------------------------------
# SNS NOTIFICATIONS
# ----------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "this" {
  count  = var.enable_sns_notifications && var.sns_topic_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "topic" {
    for_each = length(var.notification_prefixes) > 0 ? var.notification_prefixes : [""]
    content {
      topic_arn     = var.sns_topic_arn
      events        = var.notification_events
      filter_prefix = topic.value != "" ? topic.value : null
    }
  }
}
