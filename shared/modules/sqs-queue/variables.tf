# =============================================================================
# SQS QUEUE MODULE - INPUT VARIABLES
# =============================================================================

variable "name" {
  description = "Queue name"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "Time a message is hidden after being received (should be > Lambda timeout)"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "How long messages are kept (max 14 days = 1209600)"
  type        = number
  default     = 1209600
}

variable "delay_seconds" {
  description = "Delay before message becomes visible (0-900)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Max message size in bytes (max 256KB = 262144)"
  type        = number
  default     = 262144
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time (0-20 seconds)"
  type        = number
  default     = 20
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed messages"
  type        = bool
  default     = true
}

variable "dlq_max_receive_count" {
  description = "Receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "DLQ message retention"
  type        = number
  default     = 1209600
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "allowed_sender_arns" {
  description = "IAM ARNs allowed to send messages"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
