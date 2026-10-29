# ============================================================================
# LAMBDA FUNCTIONS - ROCKET BACKEND MICROSERVICES
# ============================================================================
# Rocket has 2 microservices running on AWS Lambda:
# - Core: Main business logic (contracts, billings, products, tenants)
# - Cognito: User management and authentication
#
# Both use Lambda Web Adapter to run NestJS applications.
# A third Lambda, Render (Python), turns the HTML documents of Core into PDF.
# ============================================================================

# ============================================================================
# S3 BUCKET FOR LAMBDA PACKAGES
# ============================================================================
# CI/CD uploads .zip packages here, Lambda downloads them to run.
# Flow: CI builds → uploads to S3 → Terraform updates Lambda → Lambda runs

resource "aws_s3_bucket" "lambda_packages" {
  bucket = "${local.name_prefix}-lambda-packages"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_packages" {
  bucket = aws_s3_bucket.lambda_packages.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# LAMBDA CORE - MAIN BUSINESS LOGIC
# ============================================================================
# Handles:
# - CRUD operations on DynamoDB tables
# - File operations on S3
# - Integration with Cognito for user management
# - Stripe payments
# - HubSpot CRM
# - EventBridge events to external products
# - SQS messages from external products

module "lambda_core" {
  source = "../shared/modules/lambda-function"

  # Basic configuration
  function_name = "${local.name_prefix}-core"
  description   = "Rocket Core - Main business logic"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = local.config.lambda_timeout
  memory_size   = local.config.lambda_memory_core

  # Logging
  log_retention_days = local.config.log_retention_days

  # Package source - S3 for CI/CD deployments
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  package_source = var.lambda_placeholder ? "placeholder" : "s3"
  s3_bucket      = aws_s3_bucket.lambda_packages.id
  s3_key         = "${local.environment}/${local.core_lambda_package_version}/core.zip"

  # Environment variables
  environment_variables = merge(local.standard_lambda_env_vars, {
    APP_NAME = local.rocket_services.core.app_name
    PORT     = local.rocket_services.core.port

    # Lambda Web Adapter
    AWS_LWA_PASS_THROUGH_PATH = "/${local.rocket_services.core.app_name}/events"

    # DynamoDB
    DYNAMODB_TABLE_PREFIX = "${var.project_name}_${local.environment}"

    # Cognito
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id

    # S3
    S3_BUCKET   = module.s3_files.bucket_name
    S3_BASE_URL = "https://${module.s3_files.bucket_regional_domain_name}"

    # Public images of the emails: the product logos are copied here to show them to the companies
    EMAIL_ASSETS_BUCKET   = aws_s3_bucket.email_assets.bucket
    EMAIL_ASSETS_BASE_URL = local.email_asset_base

    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    INTEGRATIONS_ENABLED = tostring(var.integrations_enabled)

    # EventBridge
    EVENTBRIDGE_BUS_NAME = aws_cloudwatch_event_bus.rocket.name

    # SQS
    SQS_INBOUND_QUEUE_URL = module.sqs_inbound.queue_url
    SQS_INBOUND_QUEUE_ARN = module.sqs_inbound.queue_arn

    # EventBridge Scheduler
    SCHEDULER_ROLE_ARN = aws_iam_role.scheduler_sqs.arn

    # Secrets (passed via CI/CD: GitHub Secrets → TF_VAR_*)
    ENCRYPTION_KEY        = var.core_encryption_key
    HUBSPOT_CLIENT_SECRET = var.core_hubspot_client_secret
    HUBSPOT_KEY           = var.core_hubspot_key

    # Stripe account of Keus, which bills the reseller subscription fees
    KEUS_STRIPE_API_KEY        = var.core_keus_stripe_api_key
    KEUS_STRIPE_WEBHOOK_SECRET = var.core_keus_stripe_webhook_secret
    KEUS_STRIPE_TAX_RATE_ID    = var.core_keus_stripe_tax_rate_id

    # Sibill, which issues the electronic invoices of Keus
    SIBILL_API_URL    = var.core_sibill_api_url
    SIBILL_API_TOKEN  = var.core_sibill_api_token
    SIBILL_COMPANY_ID = var.core_sibill_company_id

    # External
    HUBSPOT_API_URL              = var.core_hubspot_api_url
    HUBSPOT_PRODUCTS_PIPELINE_ID = var.core_hubspot_products_pipeline_id

    # DOMAIN
    DOMAIN_NAME = local.config.domain_name

    # Email - SES sender and the prefix of the templates in emails.tf
    MAIL_FROM            = local.mail_from
    MAIL_TEMPLATE_PREFIX = local.name_prefix

    # Mixpanel — read-only service account for analytics queries
    # Credentials passed via CI/CD: GitHub Secrets → TF_VAR_core_mixpanel_service_account_*
    MIXPANEL_SERVICE_ACCOUNT_USERNAME = var.core_mixpanel_service_account_username
    MIXPANEL_SERVICE_ACCOUNT_SECRET   = var.core_mixpanel_service_account_secret
    MIXPANEL_API_BASE_URL             = var.core_mixpanel_api_base_url
    MIXPANEL_ENVIRONMENT              = local.config.mixpanel_environment

    # Intercom - read-only access token for the support metrics
    # Token passed via CI/CD: GitHub Secrets → TF_VAR_core_intercom_access_token
    INTERCOM_ACCESS_TOKEN = var.core_intercom_access_token
    INTERCOM_API_URL      = var.core_intercom_api_url

    # Sentry - read-only token of an internal integration for the technical metrics
    # Token passed via CI/CD: GitHub Secrets → TF_VAR_core_sentry_auth_token
    SENTRY_AUTH_TOKEN  = var.core_sentry_auth_token
    SENTRY_ORG         = var.core_sentry_org
    SENTRY_API_URL     = var.core_sentry_api_url
    SENTRY_ENVIRONMENT = local.environment

    # Render - the Lambda that turns the HTML documents into PDF
    RENDER_FUNCTION_NAME = local.render_function_name
  })

  # IAM permissions
  iam_policy_statements = [
    # DynamoDB - Full access to all Rocket tables (created by Dynamoose)
    # Tables follow naming pattern: rocket_{environment}_{table}
    # Transactions are authorized item by item: ConditionCheckItem covers their condition-only writes.
    {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:ConditionCheckItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:CreateTable",
        # CreateTable with Tags needs it. No ListTags/UntagResource: the app never reconciles tags.
        "dynamodb:TagResource",
        "dynamodb:DescribeTable"
      ]
      resources = [
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.rocket_services.core.app_name}_${local.environment}_*"
      ]
    },

    # Cognito - User management
    {
      effect = "Allow"
      actions = [
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminDeleteUser",
        "cognito-idp:AdminGetUser",
        "cognito-idp:AdminUpdateUserAttributes",
        "cognito-idp:AdminEnableUser",
        "cognito-idp:AdminDisableUser",
        "cognito-idp:AdminResetUserPassword",
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminRemoveUserFromGroup",
        "cognito-idp:ListUsers",
        "cognito-idp:ListUsersInGroup"
      ]
      resources = [module.cognito.user_pool_arn]
    },

    # CloudWatch - API Gateway latency of the products, for the technical metrics
    # GetMetricData has no resource-level permissions: the resource is always "*".
    {
      effect    = "Allow"
      actions   = ["cloudwatch:GetMetricData"]
      resources = ["*"]
    },

    # S3 - File operations
    {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      resources = ["${module.s3_files.bucket_arn}/*"]
    },

    # S3 - Product logos copied to the public bucket of the email images
    {
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.email_assets.arn}/products/*"]
    },

    # EventBridge - Publish events to external products
    {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [aws_cloudwatch_event_bus.rocket.arn]
    },

    # SES - Send the templated communications of emails.tf; the ones with an attachment are rendered, then sent raw
    {
      effect  = "Allow"
      actions = ["ses:SendEmail", "ses:SendTemplatedEmail", "ses:SendRawEmail", "ses:TestRenderEmailTemplate"]
      resources = concat(
        # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
        aws_sesv2_email_identity.rocket[*].arn,
        [for template in aws_ses_template.core : template.arn]
      )
    },

    # SQS - Receive messages from external products
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [module.sqs_inbound.queue_arn]
    },

    # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
    # SQS - Workaround for the demo without products: core writes on its own inbound queue the answers the products
    # would send (DemoProductService). Only the products should write here: this permission should not exist.
    {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [module.sqs_inbound.queue_arn]
    },

    # SQS - Receive S3 event notifications
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        module.sqs_core_s3_events.queue_arn,
        module.sqs_core_s3_events.dlq_arn
      ]
    },

    # EventBridge Scheduler - Create/manage schedules for tier consolidation
    {
      effect = "Allow"
      actions = [
        "scheduler:CreateSchedule",
        "scheduler:DeleteSchedule",
        "scheduler:GetSchedule",
        "scheduler:UpdateSchedule"
      ]
      resources = ["arn:aws:scheduler:${var.region}:${data.aws_caller_identity.current.account_id}:schedule/default/*"]
    },

    # IAM - Pass scheduler role to EventBridge Scheduler
    {
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [aws_iam_role.scheduler_sqs.arn]
    },

    # Lambda - Render the HTML documents into PDF
    {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = ["arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${local.render_function_name}"]
    }
  ]

  tags = merge(local.common_tags, { Microservice = "core" })
}

# ============================================================================
# LAMBDA COGNITO - USER MANAGEMENT
# ============================================================================
# Dedicated Lambda for Cognito-related operations:
# - User signup/signin flows
# - Profile management
# - Password operations
# - Avatar uploads
#
# Separated from Core for:
# - Smaller deployment size
# - Independent scaling
# - Clearer responsibility

module "lambda_cognito" {
  source = "../shared/modules/lambda-function"

  # Basic configuration
  function_name = "${local.name_prefix}-cognito"
  description   = "Rocket Cognito - User management"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = local.config.lambda_timeout
  memory_size   = local.config.lambda_memory_cognito

  # Logging
  log_retention_days = local.config.log_retention_days

  # Package source - S3 for CI/CD deployments
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  package_source = var.lambda_placeholder ? "placeholder" : "s3"
  s3_bucket      = aws_s3_bucket.lambda_packages.id
  s3_key         = "${local.environment}/${local.cognito_lambda_package_version}/cognito.zip"

  # Environment variables
  environment_variables = merge(local.standard_lambda_env_vars, {
    APP_NAME = local.rocket_services.cognito.app_name
    PORT     = local.rocket_services.cognito.port

    # Lambda Web Adapter
    AWS_LWA_PASS_THROUGH_PATH = "/${local.rocket_services.cognito.app_name}/events"

    # Cognito
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id

    # S3 for avatars
    S3_BUCKET = module.s3_files.bucket_name
  })

  # IAM permissions (fewer than Core)
  iam_policy_statements = [
    # DynamoDB - The collaborators table (created by Dynamoose), projection of the pool users.
    # UpdateTable because the cognito app runs Dynamoose with update: true.
    {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:CreateTable",
        # CreateTable with Tags needs it. No ListTags/UntagResource: the app never reconciles tags.
        "dynamodb:TagResource",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable"
      ]
      resources = [
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.rocket_services.cognito.app_name}_${local.environment}_*"
      ]
    },

    # Cognito - User management
    {
      effect = "Allow"
      actions = [
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminDeleteUser",
        "cognito-idp:AdminGetUser",
        "cognito-idp:AdminUpdateUserAttributes",
        "cognito-idp:AdminEnableUser",
        "cognito-idp:AdminDisableUser",
        "cognito-idp:AdminResetUserPassword",
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminRemoveUserFromGroup",
        "cognito-idp:AdminListGroupsForUser",
        "cognito-idp:ListUsers",
        "cognito-idp:ListUsersInGroup"
      ]
      resources = [module.cognito.user_pool_arn]
    },

    # S3 - Avatar uploads (no delete, keep history)
    {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["${module.s3_files.bucket_arn}/*"]
    },

    # SQS - Receive S3 event notifications
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        module.sqs_cognito_s3_events.queue_arn,
        module.sqs_cognito_s3_events.dlq_arn
      ]
    }
  ]

  tags = merge(local.common_tags, { Microservice = "cognito" })
}

# ============================================================================
# LAMBDA RENDER - HTML TO PDF
# ============================================================================
# Python Lambda with WeasyPrint, invoked by Core: it gets an HTML document and
# returns the PDF. Stateless, so no permissions beyond its logs. Its zip carries
# the native libraries of Pango and the fonts (built by apps/render/build.sh in rocket-be).

module "lambda_render" {
  source = "../shared/modules/lambda-function"

  # Basic configuration
  function_name      = local.render_function_name
  description        = "Rocket Render - HTML documents to PDF"
  handler            = "handler.handler"
  runtime            = "python3.12"
  architecture       = "x86_64" # The native libraries in the zip are built for x86_64
  enable_web_adapter = false
  timeout            = 30
  memory_size        = local.config.lambda_memory_render

  # Logging
  log_retention_days = local.config.log_retention_days

  # Package source - S3 for CI/CD deployments
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  package_source = var.lambda_placeholder ? "placeholder" : "s3"
  s3_bucket      = aws_s3_bucket.lambda_packages.id
  s3_key         = "${local.environment}/${local.render_lambda_package_version}/render.zip"

  # The image has no fonts: fontconfig reads the ones in the zip
  environment_variables = {
    FONTCONFIG_PATH = "/var/task/fonts"
  }

  tags = merge(local.common_tags, { Microservice = "render" })
}
