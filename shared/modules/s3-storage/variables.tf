# =============================================================================
# S3 STORAGE MODULE - INPUT VARIABLES
# =============================================================================
#
# These variables configure the S3 storage bucket.
#
# =============================================================================

# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

variable "bucket_name" {
  description = <<-EOT
    S3 bucket name. Must be globally unique across ALL AWS accounts.
    Rules:
    - 3-63 characters
    - Only lowercase letters, numbers, and hyphens
    - Cannot start or end with hyphen
    - Cannot look like an IP address (e.g., 192.168.1.1)

    Example: "mycompany-dev-user-uploads"
  EOT
  type = string
}

# =============================================================================
# CORS CONFIGURATION
# =============================================================================
# Configure Cross-Origin Resource Sharing for browser access

variable "enable_cors" {
  description = "Enable CORS configuration for browser-based uploads/downloads"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = <<-EOT
    Domains allowed to make requests to this bucket.
    Required for browser-based file uploads.

    Examples:
    - ["https://app.example.com"]  = Production only
    - ["https://app.example.com", "http://localhost:4200"]  = Prod + dev
    - ["*"]  = All domains (use with caution)
  EOT
  type    = list(string)
  default = []
}

variable "cors_allowed_methods" {
  description = <<-EOT
    HTTP methods allowed for CORS requests.
    - GET: Download files
    - PUT: Upload files (presigned URLs)
    - POST: Form-based uploads
    - DELETE: Remove files
  EOT
  type    = list(string)
  default = ["GET", "PUT", "POST"]
}

variable "cors_allowed_headers" {
  description = <<-EOT
    HTTP headers allowed in CORS requests.
    ["*"] allows all headers (typical for file uploads).
  EOT
  type    = list(string)
  default = ["*"]
}

variable "cors_max_age_seconds" {
  description = <<-EOT
    How long browsers cache the CORS preflight response (seconds).
    Higher values = fewer preflight requests = faster uploads.
    3600 (1 hour) is a good default.
  EOT
  type    = number
  default = 3600
}

# =============================================================================
# VERSIONING
# =============================================================================

variable "enable_versioning" {
  description = <<-EOT
    Enable object versioning.
    Keeps all versions of objects when overwritten or deleted.

    Benefits:
    - Recover from accidental deletions
    - Restore previous versions
    - Audit trail

    Note: Increases storage costs (old versions use storage).
  EOT
  type    = bool
  default = false
}

# =============================================================================
# SECURITY
# =============================================================================

variable "block_public_access" {
  description = <<-EOT
    Block all public access to the bucket.
    Should be TRUE for application data buckets.
    Set to FALSE only for public static websites.
  EOT
  type    = bool
  default = true
}

variable "encryption_algorithm" {
  description = <<-EOT
    Server-side encryption algorithm:
    - "AES256"  = S3-managed keys (free, recommended)
    - "aws:kms" = KMS-managed keys (more control, additional cost)
  EOT
  type    = string
  default = "AES256"
}

# =============================================================================
# LIFECYCLE RULES
# =============================================================================

variable "lifecycle_rules" {
  description = <<-EOT
    Lifecycle rules for automatic object management.

    Example - Archive logs to Glacier after 90 days, delete after 365:
      [
        {
          id                       = "archive-logs"
          prefix                   = "logs/"
          enabled                  = true
          transition_days          = 90
          transition_storage_class = "GLACIER"
          expiration_days          = 365
        }
      ]
  EOT
  type = list(object({
    id                       = string                         # Rule identifier
    prefix                   = string                         # Object prefix to match
    enabled                  = bool                           # Is rule active?
    transition_days          = optional(number, null)         # Days before transition
    transition_storage_class = optional(string, "GLACIER")    # Target storage class
    expiration_days          = optional(number, null)         # Days before deletion
  }))
  default = []
}

variable "abort_incomplete_multipart_days" {
  description = <<-EOT
    Days after which to abort incomplete multipart uploads.
    Multipart uploads that fail leave partial data that costs money.
    7 days is a safe default.
  EOT
  type    = number
  default = 7
}

# =============================================================================
# SNS NOTIFICATIONS
# =============================================================================

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for S3 events"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to receive S3 event notifications"
  type        = string
  default     = ""
}

variable "notification_prefixes" {
  description = <<-EOT
    Object prefixes to filter notifications.
    Example: ["uploads/", "exports/"]
    Empty list = notify for all objects.
  EOT
  type    = list(string)
  default = []
}

variable "notification_events" {
  description = <<-EOT
    S3 events that trigger notifications.
    Common events:
    - "s3:ObjectCreated:*"  = Any object creation
    - "s3:ObjectRemoved:*"  = Any deletion
    - "s3:ObjectCreated:Put" = Only PUT operations
  EOT
  type    = list(string)
  default = ["s3:ObjectCreated:*"]
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}
