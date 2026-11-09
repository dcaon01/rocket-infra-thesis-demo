# ============================================================================
# INBOUND SQS QUEUE - PRODUCTS SEND MESSAGES BACK TO ROCKET
# ============================================================================
# External products can send messages to Rocket via this queue.
# Lambda Core processes incoming messages.
#
# HOW TO ALLOW A PRODUCT TO SEND MESSAGES:
# ----------------------------------------
# 1. Add the product's Lambda execution role ARN to product_sqs_writer_arns
#    in the relevant env_config block in locals.tf:
#
#    product_sqs_writer_arns = [
#      "arn:aws:iam::123456789:role/my-product-lambda-role"
#    ]
#
# 2. In the product's Lambda, send messages to the queue URL (from outputs).
#
# Message format expected by Rocket Core:
# {
#   "source": "product-id",
#   "type": "response.type",
#   "payload": { ... }
# }
# ============================================================================

module "sqs_inbound" {
  source = "../shared/modules/sqs-queue"

  name                       = "${local.name_prefix}-inbound"
  visibility_timeout_seconds = local.config.lambda_timeout + 10 # Must be > Lambda timeout
  message_retention_seconds  = 1209600                          # 14 days
  receive_wait_time_seconds  = 20                               # Long polling
  dlq_max_receive_count      = 3
  allowed_sender_arns        = local.config.product_sqs_writer_arns
  tags                       = local.common_tags
}

# Trigger Lambda Core when messages arrive
resource "aws_lambda_event_source_mapping" "rocket_inbound" {
  event_source_arn                   = module.sqs_inbound.queue_arn
  function_name                      = module.lambda_core.function_arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  enabled                            = true
}

# ============================================================================
# S3 EVENT QUEUES - S3 NOTIFICATIONS ROUTED TO LAMBDAS VIA SQS
# ============================================================================
# S3 sends notifications to SQS queues, which trigger Lambda functions.
# This avoids direct S3→Lambda invocation which doesn't work with
# Lambda Web Adapter (non-HTTP events need AWS_LWA_PASS_THROUGH_PATH).
#
# Routing:
#   contracts/* → SQS core-s3-events   → Lambda Core
#   products/*  → SQS core-s3-events   → Lambda Core
#   resellers/* → SQS core-s3-events   → Lambda Core
#   billings/*  → SQS core-s3-events   → Lambda Core
#   users/*     → SQS cognito-s3-events → Lambda Cognito
# ============================================================================

# ----------------------------------------------------------------------------
# CORE S3 EVENTS QUEUE
# ----------------------------------------------------------------------------

module "sqs_core_s3_events" {
  source = "../shared/modules/sqs-queue"

  name                       = "${local.name_prefix}-core-s3-events"
  visibility_timeout_seconds = local.config.lambda_timeout + 10
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 20
  dlq_max_receive_count      = 3
  tags                       = local.common_tags
}

# Allow S3 bucket to send notifications to the core queue
resource "aws_sqs_queue_policy" "core_s3_events" {
  queue_url = module.sqs_core_s3_events.queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3SendMessage"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = module.sqs_core_s3_events.queue_arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = module.s3_files.bucket_arn
        }
      }
    }]
  })
}

# Trigger Lambda Core when S3 events arrive
resource "aws_lambda_event_source_mapping" "core_s3_events" {
  event_source_arn = module.sqs_core_s3_events.queue_arn
  function_name    = module.lambda_core.function_arn
  batch_size       = 1
  enabled          = true
}

# ----------------------------------------------------------------------------
# COGNITO S3 EVENTS QUEUE
# ----------------------------------------------------------------------------

module "sqs_cognito_s3_events" {
  source = "../shared/modules/sqs-queue"

  name                       = "${local.name_prefix}-cognito-s3-events"
  visibility_timeout_seconds = local.config.lambda_timeout + 10
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 20
  dlq_max_receive_count      = 3
  tags                       = local.common_tags
}

# Allow S3 bucket to send notifications to the cognito queue
resource "aws_sqs_queue_policy" "cognito_s3_events" {
  queue_url = module.sqs_cognito_s3_events.queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3SendMessage"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = module.sqs_cognito_s3_events.queue_arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = module.s3_files.bucket_arn
        }
      }
    }]
  })
}

# Trigger Lambda Cognito when S3 events arrive
resource "aws_lambda_event_source_mapping" "cognito_s3_events" {
  event_source_arn = module.sqs_cognito_s3_events.queue_arn
  function_name    = module.lambda_cognito.function_arn
  batch_size       = 1
  enabled          = true
}
