# ============================================================================
# SQS QUEUE MODULE
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
# DEAD LETTER QUEUE
# ----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                      = "${var.name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = var.enable_encryption

  tags = var.tags
}

# ----------------------------------------------------------------------------
# MAIN QUEUE
# ----------------------------------------------------------------------------

resource "aws_sqs_queue" "this" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  sqs_managed_sse_enabled    = var.enable_encryption

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  tags = var.tags
}

# ----------------------------------------------------------------------------
# QUEUE POLICY
# ----------------------------------------------------------------------------

resource "aws_sqs_queue_policy" "this" {
  count     = length(var.allowed_sender_arns) > 0 ? 1 : 0
  queue_url = aws_sqs_queue.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSenders"
      Effect = "Allow"
      Principal = {
        AWS = var.allowed_sender_arns
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.this.arn
    }]
  })
}
