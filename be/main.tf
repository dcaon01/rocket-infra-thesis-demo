# ============================================================================
# MAIN - ROCKET BACKEND INFRASTRUCTURE
# ============================================================================
#
# This file contains data sources that query AWS for information needed by
# other files. Terraform reads ALL .tf files in this directory as ONE config.
#
# ============================================================================

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

# AWS Caller Identity - queries "who am I?" to AWS
# Used for account validation and ARN construction
data "aws_caller_identity" "current" {}

# AWS Region - queries which region we're operating in
data "aws_region" "current" {}

# GitHub OIDC Provider (data source) - for CI/CD authentication
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}
