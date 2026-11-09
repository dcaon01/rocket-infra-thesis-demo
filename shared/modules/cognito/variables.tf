# ============================================================================
# COGNITO MODULE - VARIABLES
# ============================================================================

variable "name" {
  description = "User Pool name"
  type        = string
}

variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'"
  }
}

# Password policy
variable "password_minimum_length" {
  description = "Minimum password length (default 8)"
  type        = number
  default     = 8
}

variable "password_require_lowercase" {
  type    = bool
  default = true
}

variable "password_require_numbers" {
  type    = bool
  default = true
}

variable "password_require_symbols" {
  type    = bool
  default = true
}

variable "password_require_uppercase" {
  type    = bool
  default = true
}

variable "temporary_password_validity_days" {
  type    = number
  default = 7
}

# MFA
variable "mfa_configuration" {
  description = "OFF, OPTIONAL, or ON"
  type        = string
  default     = "OPTIONAL"
  validation {
    condition     = contains(["OFF", "OPTIONAL", "ON"], var.mfa_configuration)
    error_message = "Must be 'OFF', 'OPTIONAL', or 'ON'"
  }
}

# User creation
variable "allow_admin_create_user_only" {
  description = "true = B2B (admin creates), false = B2C (self-signup)"
  type        = bool
  default     = true
}

# Email templates
variable "email_verification_subject" {
  type    = string
  default = "Verify your account"
}

variable "email_verification_message" {
  description = "Use {####} for verification code"
  type        = string
  default     = "Your verification code is {####}"
}

variable "invite_email_subject" {
  type    = string
  default = "Welcome to the application"
}

variable "invite_email_message" {
  description = "Use {username} for email, {####} for password"
  type        = string
  default     = "Hello {username}, your temporary password is {####}"
}

# Email sending
variable "ses_identity_arn" {
  description = "Verified SES identity to send from. null keeps Cognito's default sender."
  type        = string
  default     = null
}

variable "from_email_address" {
  description = "From address, e.g. \"Brand <noreply@example.com>\". Used only with ses_identity_arn."
  type        = string
  default     = null
}

# Custom attributes
variable "custom_attributes" {
  description = "Custom user attributes (appear as custom:name in JWT)"
  type = list(object({
    name       = string
    type       = string
    min_length = optional(number, 0)
    max_length = optional(number, 256)
    required   = optional(bool, false)
    mutable    = optional(bool, true)
  }))
  default = []
}

# App client
variable "client_name" {
  type    = string
  default = "web-client"
}

variable "access_token_validity" {
  description = "Hours"
  type        = number
  default     = 1
}

variable "id_token_validity" {
  description = "Hours"
  type        = number
  default     = 1
}

variable "refresh_token_validity" {
  description = "Days"
  type        = number
  default     = 30
}

# User groups
variable "groups" {
  description = "User groups for authorization"
  type = list(object({
    name        = string
    description = optional(string, "")
    precedence  = optional(number, 0)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
