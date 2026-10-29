# ============================================================================
# BOOTSTRAP VARIABLES - STATE BACKEND SETUP
# ============================================================================
variable "region" {
  description = "AWS region for state backend"
  type        = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS profile to use for bootstrap"
  type        = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "damiano-sephiro"
}

variable "namespace" {
  description = "Namespace for resource naming (organization identifier)"
  type        = string
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  default = "dcaon01"
}

variable "environment" {
  description = "Environment identifier (should match account type)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be one of: dev, prod"
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "rocket"
}

variable "component" {
  description = "Component name (backend or frontend)"
  type        = string
  validation {
    condition     = contains(["backend", "frontend"], var.component)
    error_message = "Component must be either 'backend' or 'frontend'"
  }
}