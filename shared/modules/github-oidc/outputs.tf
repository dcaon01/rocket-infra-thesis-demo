# =============================================================================
# GITHUB OIDC MODULE - OUTPUTS
# =============================================================================
#
# These outputs expose values needed for GitHub Actions configuration.
#
# =============================================================================

output "oidc_provider_arn" {
  description = <<-EOT
    OIDC provider ARN.

    If you created the provider (create_oidc_provider = true),
    share this ARN with other stacks that need to reference it.

    Store this as a GitHub variable or Terraform output for fe/ to use.
  EOT
  value = local.oidc_provider_arn
}

output "role_arn" {
  description = <<-EOT
    IAM role ARN that GitHub Actions will assume.

    Configure this in your GitHub workflow:

    ```yaml
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: <this value>
        aws-region: eu-north-1
    ```

    Also store as a GitHub Actions variable:
      Settings > Secrets and variables > Actions > Variables
      AWS_ROLE_ARN = <this value>
  EOT
  value = aws_iam_role.this.arn
}

output "role_name" {
  description = <<-EOT
    IAM role name.

    Useful for debugging and referencing in other Terraform resources.
  EOT
  value = aws_iam_role.this.name
}
