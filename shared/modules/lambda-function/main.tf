# ============================================================================
# LAMBDA FUNCTION MODULE
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8"
    }
  }
}

data "aws_region" "current" {}

# ----------------------------------------------------------------------------
# IAM ROLE
# ----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  count = length(var.iam_policy_statements) > 0 ? 1 : 0

  name = "${var.function_name}-custom-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for stmt in var.iam_policy_statements : {
        Effect   = stmt.effect
        Action   = stmt.actions
        Resource = stmt.resources
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ----------------------------------------------------------------------------
# PLACEHOLDER CODE (initial deployment)
# ----------------------------------------------------------------------------

data "archive_file" "placeholder" {
  count       = var.package_source == "placeholder" ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: 'placeholder' });"
    filename = "main.js"
  }
}

# ----------------------------------------------------------------------------
# LAMBDA FUNCTION
# ----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = [var.architecture]

  # Lambda Web Adapter for NestJS
  layers = var.enable_web_adapter ? [
    "arn:aws:lambda:${data.aws_region.current.id}:753240598075:layer:LambdaAdapterLayerArm64:24"
  ] : []

  # Package source
  filename         = var.package_source == "placeholder" ? data.archive_file.placeholder[0].output_path : (var.package_source == "local" ? var.local_filename : null)
  source_code_hash = var.package_source == "placeholder" ? data.archive_file.placeholder[0].output_base64sha256 : (var.package_source == "local" ? filebase64sha256(var.local_filename) : null)
  s3_bucket        = var.package_source == "s3" ? var.s3_bucket : null
  s3_key           = var.package_source == "s3" ? var.s3_key : null

  # Concurrency
  reserved_concurrent_executions = var.reserved_concurrent_executions != -1 ? var.reserved_concurrent_executions : null

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_logs
  ]

  tags = var.tags
}
