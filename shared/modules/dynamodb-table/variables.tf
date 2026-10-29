# ============================================================================
# DYNAMODB TABLE MODULE - VARIABLES
# ============================================================================

variable "name" {
  description = "Table name"
  type        = string
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Must be 'PAY_PER_REQUEST' or 'PROVISIONED'"
  }
}

# Primary key
variable "hash_key" {
  description = "Partition key name"
  type        = string
  default     = "id"
}

variable "hash_key_type" {
  description = "S (String), N (Number), B (Binary)"
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "Sort key name (optional, empty = none)"
  type        = string
  default     = ""
}

variable "range_key_type" {
  type    = string
  default = "S"
}

# Provisioned capacity (only for PROVISIONED mode)
variable "read_capacity" {
  type    = number
  default = 5
}

variable "write_capacity" {
  type    = number
  default = 5
}

# Additional attributes for indexes
variable "attributes" {
  description = "Additional attributes for indexes"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

# Global Secondary Indexes
variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string, null)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), null)
    read_capacity      = optional(number, 5)
    write_capacity     = optional(number, 5)
  }))
  default = []
}

# Local Secondary Indexes
variable "local_secondary_indexes" {
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), null)
  }))
  default = []
}

# Data protection
variable "point_in_time_recovery_enabled" {
  description = "Enable PITR (restore to any second in last 35 days)"
  type        = bool
  default     = false
}

# TTL
variable "ttl_attribute_name" {
  description = "Attribute for TTL (empty = disabled)"
  type        = string
  default     = ""
}

# Streams
variable "stream_enabled" {
  type    = bool
  default = false
}

variable "stream_view_type" {
  description = "KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "tags" {
  type    = map(string)
  default = {}
}
