# =============================================================================
# GITHUB OIDC MODULE - INPUT VARIABLES
# =============================================================================
#
# These variables configure GitHub Actions OIDC authentication with AWS.
#
# =============================================================================

# =============================================================================
# NAMING
# =============================================================================

variable "name_prefix" {
  description = "Name prefix for resources (not used directly, but kept for consistency)"
  type        = string
}

# =============================================================================
# GITHUB CONFIGURATION
# =============================================================================

variable "github_org" {
  description = <<-EOT
    GitHub organization or username.
    Example: "mycompany" for github.com/mycompany/repo
  EOT
  type = string
}

variable "github_repos" {
  description = <<-EOT
    List of GitHub repository names that can assume this role.

    Examples:
    - ["rocket-fe"]              - Single repo
    - ["rocket-fe", "rocket-be"] - Multiple repos

    Security note: Be specific! Each repo listed can assume this role.
  EOT
  type = list(string)
}

# =============================================================================
# OIDC PROVIDER CONFIGURATION
# =============================================================================

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the OIDC provider.

    IMPORTANT: Only ONE OIDC provider per AWS account!

    Set to true for the first stack that needs OIDC.
    Set to false for subsequent stacks (reference existing provider).

    Typical setup:
    - be/ creates provider (create_oidc_provider = true)
    - fe/ references it (create_oidc_provider = false, provide existing ARN)
  EOT
  type    = bool
  default = true
}

variable "existing_oidc_provider_arn" {
  description = <<-EOT
    ARN of existing OIDC provider (when create_oidc_provider = false).

    Get this from the output of the stack that created the provider:
      terraform output -raw oidc_provider_arn

    Leave empty when create_oidc_provider = true.
  EOT
  type    = string
  default = ""
}

# =============================================================================
# IAM ROLE CONFIGURATION
# =============================================================================

variable "role_name" {
  description = <<-EOT
    IAM role name that GitHub Actions will assume.

    Convention: {project}-{env}-{purpose}-role
    Examples:
    - "rocket-dev-fe-deploy-role"
    - "rocket-prod-be-ci-role"
  EOT
  type = string
}

variable "role_description" {
  description = "Human-readable description for the IAM role"
  type        = string
  default     = "GitHub Actions deployment role"
}

variable "policy_statements" {
  description = <<-EOT
    IAM policy statements defining what the role can do.

    Example - Frontend deployment:
      [
        {
          effect    = "Allow"
          actions   = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
          resources = ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
        },
        {
          effect    = "Allow"
          actions   = ["cloudfront:CreateInvalidation"]
          resources = ["arn:aws:cloudfront::123456789012:distribution/E1234"]
        }
      ]

    Best practices:
    - Be specific with actions (don't use "*")
    - Be specific with resources (use exact ARNs)
    - Use least privilege (only grant what's needed)
  EOT
  type = list(object({
    effect    = string        # "Allow" or "Deny"
    actions   = list(string)  # List of AWS actions
    resources = list(string)  # List of resource ARNs
  }))
  default = []
}

variable "create_admin_policy" {
  description = <<-EOT
    Whether to attach an admin policy (Action: *, Resource: *) to this role.

    Use this for Terraform roles that need full access to plan/apply
    all resources in the AWS account. Without this, Terraform cannot
    refresh the state of resources it doesn't have explicit permissions for.

    IMPORTANT: Only use for Terraform roles, NOT for CI roles.
    CI roles should use policy_statements with least-privilege permissions.
  EOT
  type    = bool
  default = false
}

variable "max_session_duration" {
  description = <<-EOT
    Maximum session duration in seconds for temporary credentials.

    Range: 3600 (1 hour) to 43200 (12 hours)
    Default: 3600 (1 hour)

    Longer sessions are useful for long-running deployments,
    but shorter sessions are more secure.
  EOT
  type    = number
  default = 3600
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "Tags to apply to OIDC and IAM resources"
  type        = map(string)
  default     = {}
}
