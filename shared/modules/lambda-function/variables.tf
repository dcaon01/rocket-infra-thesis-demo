# ============================================================================
# LAMBDA FUNCTION MODULE - VARIABLES
# ============================================================================

variable "function_name" {
  description = "Lambda function name (must be unique in the AWS account)"
  type        = string
}

variable "description" {
  description = "Human-readable description"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Entry point: 'filename.functionName' (e.g., 'main.handler')"
  type        = string
  default     = "main.handler"
}

variable "runtime" {
  description = "Runtime: nodejs20.x, python3.11, java21, etc."
  type        = string
  default     = "nodejs20.x"
}

variable "architecture" {
  description = "Architecture: x86_64 or arm64 (Graviton2, 20% cheaper)"
  type        = string
  default     = "arm64"
}

variable "timeout" {
  description = "Max execution time in seconds (1-900)"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "RAM in MB (128-10240). More memory = more CPU."
  type        = number
  default     = 256
}

variable "enable_web_adapter" {
  description = "Enable Lambda Web Adapter layer for running web frameworks (NestJS, Express)"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Environment variables available to Lambda code"
  type        = map(string)
  default     = {}
}

variable "iam_policy_statements" {
  description = "Additional IAM permissions for Lambda"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "log_retention_days" {
  description = "CloudWatch logs retention (0 = forever)"
  type        = number
  default     = 14
}

variable "package_source" {
  description = "Code source: 'placeholder', 's3', or 'local'"
  type        = string
  default     = "placeholder"

  validation {
    condition     = contains(["placeholder", "s3", "local"], var.package_source)
    error_message = "package_source must be 'placeholder', 's3', or 'local'"
  }
}

variable "s3_bucket" {
  description = "S3 bucket for Lambda code (when package_source = 's3')"
  type        = string
  default     = ""
}

variable "s3_key" {
  description = "S3 key for Lambda zip (when package_source = 's3')"
  type        = string
  default     = ""
}

variable "local_filename" {
  description = "Local zip path (when package_source = 'local')"
  type        = string
  default     = ""
}

variable "reserved_concurrent_executions" {
  description = "Concurrency limit. -1 = unlimited, 0 = disabled"
  type        = number
  default     = -1
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
