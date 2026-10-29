# ============================================================================
# S3 FRONTEND STATIC HOSTING MODULE VARIABLES
# ============================================================================

# Basic Configuration
variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

# S3 Configuration
variable "bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  type        = string
  default     = ""
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = false
}

# Security Configuration
variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket access"
  type        = bool
  default     = true
}

# CloudFront Integration
variable "cloudfront_oac_arn" {
  description = "CloudFront Origin Access Control ARN for secure access"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
