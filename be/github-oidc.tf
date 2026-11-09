# ============================================================================
# GITHUB OIDC - CI/CD AUTHENTICATION
# ============================================================================
# Enables GitHub Actions to deploy to AWS without long-lived credentials.
#
# Two roles:
# 1. CI Role: Build and upload Lambda packages to S3
# 2. Terraform Role: Run terraform apply to update infrastructure
#
# IMPORTANT: OIDC provider already exists in AWS account.
# Both roles reference the existing provider.
# ============================================================================

# ----------------------------------------------------------------------------
# CI ROLE - BUILD AND UPLOAD
# ----------------------------------------------------------------------------
# Used by GitHub Actions to:
# - Build Lambda packages (npm run build)
# - Upload .zip files to S3

module "github_oidc_ci" {
  source = "../shared/modules/github-oidc"

  name_prefix                = local.name_prefix
  github_org                 = var.github_org
  github_repos               = [var.github_repo] # rocket.be
  create_oidc_provider       = false             # OIDC provider already exists in AWS account
  existing_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  role_name                  = "${local.name_prefix}-be-ci-role"
  role_description           = "GitHub Actions role for backend CI (build and upload)"

  policy_statements = [
    {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.lambda_packages.arn,
        "${aws_s3_bucket.lambda_packages.arn}/*"
      ]
    }
  ]

  tags = local.common_tags
}

# ----------------------------------------------------------------------------
# TERRAFORM ROLE - INFRASTRUCTURE DEPLOYMENT
# ----------------------------------------------------------------------------
# Used by GitHub Actions to:
# - Run terraform plan/apply
# - Update Lambda function code
#
# Can be assumed by both rocket.be (for Lambda updates) and rocket-infra (for full infra)

module "github_oidc_terraform" {
  source = "../shared/modules/github-oidc"

  name_prefix = local.name_prefix
  github_org  = var.github_org
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  github_repos               = [var.github_repo, "rocket-infra-thesis-demo"]
  create_oidc_provider       = false # Reference existing provider
  existing_oidc_provider_arn = module.github_oidc_ci.oidc_provider_arn
  role_name                  = "${local.name_prefix}-be-terraform-role"
  role_description           = "GitHub Actions role for backend Terraform deployments"
  create_admin_policy        = true # Full access needed for terraform plan/apply to refresh all resources

  tags = local.common_tags
}
