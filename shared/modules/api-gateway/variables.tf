# =============================================================================
# API GATEWAY MODULE - INPUT VARIABLES
# =============================================================================

variable "name" {
  description = "API Gateway name (displayed in AWS console)"
  type        = string
}

variable "description" {
  description = "Human-readable description of what this API does"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Stage name (appears in URL: .../stage-name/endpoint). Examples: dev, staging, prod"
  type        = string
}

# =============================================================================
# CORS CONFIGURATION
# =============================================================================

variable "cors_allow_origins" {
  description = "List of domains allowed to call this API from browsers. Example: [\"https://app.example.com\"]"
  type        = list(string)
  default     = []
}

variable "cors_allow_methods" {
  description = "HTTP methods allowed for CORS requests"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
}

variable "cors_allow_headers" {
  description = "Headers clients can send. Must include Authorization for JWT auth."
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
}

variable "cors_max_age" {
  description = "How long browsers cache CORS preflight response (seconds). Higher = fewer preflight requests."
  type        = number
  default     = 3600
}

variable "cors_allow_credentials" {
  description = "Allow cookies and Authorization headers in CORS requests. Required for JWT auth."
  type        = bool
  default     = true
}

# =============================================================================
# JWT AUTHORIZATION (COGNITO)
# =============================================================================

variable "jwt_issuer" {
  description = "JWT issuer URL (Cognito User Pool URL). Format: https://cognito-idp.{region}.amazonaws.com/{pool-id}"
  type        = string
  default     = ""
}

variable "jwt_audience" {
  description = "JWT audience - Cognito App Client IDs that can use this API"
  type        = list(string)
  default     = []
}

variable "enable_jwt_authorizer" {
  description = "Enable JWT authorizer for protected routes. Set to false for fully public APIs."
  type        = bool
  default     = true
}

# =============================================================================
# THROTTLING (RATE LIMITING)
# =============================================================================

variable "throttling_burst_limit" {
  description = "Max concurrent requests (handles traffic spikes). Example: 100"
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "Sustained requests per second. Example: 50 req/sec"
  type        = number
  default     = 50
}

# =============================================================================
# LOGGING
# =============================================================================

variable "log_retention_days" {
  description = "How long to keep API Gateway access logs in CloudWatch"
  type        = number
  default     = 14
}

# =============================================================================
# INTEGRATIONS AND ROUTES
# =============================================================================

variable "integrations" {
  description = <<-EOT
    Map of Lambda integrations. Each Lambda needs one integration.
    Example:
      {
        core = {
          lambda_invoke_arn = "arn:aws:apigateway:..."
          lambda_arn        = "arn:aws:lambda:..."
        }
      }
  EOT
  type = map(object({
    lambda_invoke_arn = string # Lambda invoke ARN (for API Gateway)
    lambda_arn        = string # Lambda ARN (for permissions)
  }))
  default = {}
}

variable "routes" {
  description = <<-EOT
    List of routes to create. Each route maps an HTTP request to a Lambda.
    Example:
      [
        { route_key = "GET /users", integration_id = "core", require_auth = true },
        { route_key = "POST /users", integration_id = "core", require_auth = true },
        { route_key = "GET /health", integration_id = "core", require_auth = false }
      ]
  EOT
  type = list(object({
    route_key      = string # HTTP method + path, e.g., "GET /users"
    integration_id = string # Key from integrations map
    require_auth   = bool   # true = requires JWT, false = public
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
