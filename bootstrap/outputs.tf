# =============================================================================
# bootstrap/outputs.tf - Outputs for backend configuration
# =============================================================================

# output "state_bucket_name" {
#   description = "S3 bucket name for Terraform state"
#   value       = aws_s3_bucket.terraform_state.id
# }

# output "state_bucket_arn" {
#   description = "S3 bucket ARN for Terraform state"
#   value       = aws_s3_bucket.terraform_state.arn
# }

# output "dynamodb_table_name" {
#   description = "DynamoDB table name for state locking"
#   value       = aws_dynamodb_table.terraform_locks.name
# }

# output "backend_config_instructions" {
#   description = "Instructions for configuring backend"
#   value       = <<-EOT

#     Backend configuration complete!

#     Use these values in your backend-configs/*.tfbackend files:

#     bucket         = "${aws_s3_bucket.terraform_state.id}"
#     region         = "${var.aws_region}"
#     dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
#     encrypt        = true

#   EOT
# }
