# ============================================================================
# DYNAMODB TABLE MODULE - OUTPUTS
# ============================================================================

output "table_name" {
  description = "Table name"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "Table ARN"
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "Table ID"
  value       = aws_dynamodb_table.this.id
}

output "stream_arn" {
  description = "Stream ARN (null if disabled)"
  value       = aws_dynamodb_table.this.stream_arn
}

output "index_arns" {
  description = "ARN pattern for all indexes"
  value       = "${aws_dynamodb_table.this.arn}/index/*"
}
