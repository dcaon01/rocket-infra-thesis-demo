# ============================================================================
# GITHUB OIDC FRONTEND ROLE - ROCKET FRONTEND
# ============================================================================

# Look up existing OIDC provider (created by backend)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# GitHub OIDC Role for Frontend Deployment
module "frontend_github_oidc" {
  source = "../shared/modules/github-oidc"

  # Basic Configuration
  name_prefix = local.name_prefix
  github_org  = var.github_org
  github_repos = [var.github_repo]

  # Reuse existing OIDC provider (created in backend)
  create_oidc_provider      = false
  existing_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # Role Configuration
  role_name        = "${local.name_prefix}-fe-deploy-role"
  role_description = "GitHub Actions role for Rocket frontend deployment"

  # S3 + CloudFront permissions for deployment
  policy_statements = [
    {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      resources = [
        module.frontend_hosting.bucket_arn,
        "${module.frontend_hosting.bucket_arn}/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ]
      resources = [module.frontend_cdn.distribution_arn]
    }
  ]

  tags = local.common_tags
}
