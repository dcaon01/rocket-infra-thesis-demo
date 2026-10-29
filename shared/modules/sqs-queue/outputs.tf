# =============================================================================
# SQS QUEUE MODULE - OUTPUTS
# =============================================================================

output "queue_url" {
  description = "SQS queue URL (for sending/receiving)"
  value       = aws_sqs_queue.this.url
}

output "queue_arn" {
  description = "SQS queue ARN (for IAM policies)"
  value       = aws_sqs_queue.this.arn
}

output "queue_name" {
  description = "SQS queue name"
  value       = aws_sqs_queue.this.name
}

output "dlq_url" {
  description = "DLQ URL"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "DLQ ARN"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_name" {
  description = "DLQ name"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].name : null
}
