# =============================================================================
# S3 STORAGE MODULE - OUTPUTS
# =============================================================================
#
# These outputs expose important values from the S3 bucket.
# Use these for Lambda environment variables, IAM policies, etc.
#
# =============================================================================

output "bucket_name" {
  description = <<-EOT
    S3 bucket name.
    Use this in application code to reference the bucket.

    Example (Node.js):
      const params = {
        Bucket: process.env.S3_BUCKET_NAME,
        Key: 'uploads/file.pdf'
      };
  EOT
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = <<-EOT
    S3 bucket ARN (Amazon Resource Name).
    Use this in IAM policies to grant access.

    Example IAM policy:
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:PutObject"],
        "Resource": "<bucket_arn>/*"
      }

    Note: For object access, append "/*" to the ARN.
  EOT
  value = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = <<-EOT
    Bucket regional domain name.
    Format: bucket-name.s3.region.amazonaws.com

    Use this for:
    - CloudFront origins
    - Direct HTTPS access to bucket
  EOT
  value = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = <<-EOT
    Bucket global domain name.
    Format: bucket-name.s3.amazonaws.com

    Note: Regional domain name is preferred for new applications.
  EOT
  value = aws_s3_bucket.this.bucket_domain_name
}
