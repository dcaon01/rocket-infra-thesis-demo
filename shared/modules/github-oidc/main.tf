# ============================================================================
# GITHUB OIDC MODULE
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8"
    }
  }
}

# ----------------------------------------------------------------------------
# OIDC PROVIDER
# ----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  arn   = var.existing_oidc_provider_arn
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  # Newer repos sign the token with the immutable subject (repo:org@id/repo@id), which GitHub does not let them turn off.
  repo_conditions = flatten([for repo in var.github_repos : [
    "repo:${var.github_org}/${repo}:*",
    "repo:${var.github_org}@*/${repo}@*:*",
  ]])
}

# ----------------------------------------------------------------------------
# IAM ROLE
# ----------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = local.repo_conditions
        }
      }
    }]
  })

  tags = var.tags
}

# ----------------------------------------------------------------------------
# IAM POLICY
# ----------------------------------------------------------------------------

resource "aws_iam_role_policy" "this" {
  count = length(var.policy_statements) > 0 && !var.create_admin_policy ? 1 : 0

  name = "${var.role_name}-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for stmt in var.policy_statements : {
        Effect   = stmt.effect
        Action   = stmt.actions
        Resource = stmt.resources
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# ADMIN POLICY (for Terraform roles that need full access)
# ----------------------------------------------------------------------------

resource "aws_iam_policy" "admin" {
  count = var.create_admin_policy ? 1 : 0

  name        = "${var.role_name}-admin-policy"
  description = "Administrative policy for Terraform operations with full access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = var.create_admin_policy ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.admin[0].arn
}
