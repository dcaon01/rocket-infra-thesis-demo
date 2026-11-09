# ============================================================================
# S3 EVENT NOTIFICATIONS - SQS TRIGGERS
# ============================================================================
# Configures S3 to send notifications to SQS queues when files are uploaded
# to specific folders. SQS then triggers the appropriate Lambda function.
#
# Flow:
# 1. File uploaded to S3 bucket
# 2. S3 checks notification rules (filter by prefix)
# 3. If match, S3 sends message to the configured SQS queue
# 4. SQS triggers Lambda via event source mapping (configured in sqs.tf)
# 5. Lambda receives event with file details (bucket, key, size, etc.)
# ============================================================================

resource "aws_s3_bucket_notification" "app_files_sqs" {
  bucket = module.s3_files.bucket_name

  # Contracts → SQS Core (process contract PDFs)
  queue {
    queue_arn     = module.sqs_core_s3_events.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "contracts/"
  }

  # Products → SQS Core (process product images)
  queue {
    queue_arn     = module.sqs_core_s3_events.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "products/"
  }

  # Resellers → SQS Core (save the logo key on the reseller)
  queue {
    queue_arn     = module.sqs_core_s3_events.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "resellers/"
  }

  # Billings → SQS Core (save the payment proof key on the billing)
  queue {
    queue_arn     = module.sqs_core_s3_events.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "billings/"
  }

  # User avatars → SQS Cognito (resize images, update profile)
  queue {
    queue_arn     = module.sqs_cognito_s3_events.queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "users/"
  }

  depends_on = [
    aws_sqs_queue_policy.core_s3_events,
    aws_sqs_queue_policy.cognito_s3_events,
    module.s3_files
  ]
}
