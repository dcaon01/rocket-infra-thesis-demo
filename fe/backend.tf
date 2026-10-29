# =============================================================================
# fe/backend.tf - Remote state configuration
# =============================================================================
# Terraform state is stored in S3 with DynamoDB locking.
#
# Initialize with:
#   terraform init -backend-config=../backend-configs/dev-frontend.tfbackend
#   terraform init -backend-config=../backend-configs/prod-frontend.tfbackend
#
# To switch environments:
#   terraform init -reconfigure -backend-config=../backend-configs/{env}-frontend.tfbackend
# =============================================================================

terraform {
  backend "s3" {
    # Actual values come from .tfbackend files
  }
}
