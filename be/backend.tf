# ============================================================================
# TERRAFORM BACKEND CONFIGURATION - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================
# Backend configuration is provided via auto-generated files from bootstrap.
# Files are in ../backend-configs/ directory.
#
# Usage:
#   terraform init -backend-config=../backend-configs/dev-backend.tfbackend
#   terraform init -backend-config=../backend-configs/prod-backend.tfbackend
#
# To switch environments, run:
#   terraform init -reconfigure -backend-config=../backend-configs/{env}-backend.tfbackend
# ============================================================================

terraform {
  backend "s3" {
    # Values provided via -backend-config flag:
    # - bucket         = S3 bucket name for state storage
    # - key            = Path within bucket (e.g., "backend/dev/terraform.tfstate")
    # - region         = AWS region where bucket exists
    # - dynamodb_table = DynamoDB table for state locking
    # - encrypt        = Whether to encrypt state at rest (always true!)
  }
}
