# ============================================================================
# EVENTBRIDGE - ROCKET EVENT-DRIVEN COMMUNICATION
# ============================================================================
# Rocket publishes events to external products via EventBridge.
# Each product has its own EventBridge bus — Rocket forwards events there.
# The product is responsible for routing events to its own microservices.
#
# Event format (sent by Core via EventBridge SDK):
#   Source:     "rocket"
#   DetailType: "rocket-notification"
#   Detail:     { productId: "product-uuid", operation: "created", entityType: "contract", payload: [...] }
#
# Flow: Core → Rocket bus → rule (matches productId) → product's bus
#       The product then defines its own rules to route to its microservices.
#
# HOW TO ADD A NEW PRODUCT:
# -------------------------
# 1. In locals.tf, add to the products_config map inside the relevant
#    environment (dev/prod) in env_config:
#
#    products_config = {
#      "nquadro" = {
#        product_id = "nquadro-uuid"
#        enabled    = true
#        event_bus_arn = "arn:aws:events:eu-north-1:123456789:event-bus/nquadro-dev-events"
#      }
#      "genio" = {
#        product_id = "genio-uuid"
#        enabled    = true
#        event_bus_arn = "arn:aws:events:eu-west-1:123456789:event-bus/genio-dev-events"
#      }
#    }
#
# 2. Events matching the productId will be forwarded to the product's bus.
#    Cross-region buses are supported natively by EventBridge.
#
# 3. If the product needs to send messages back to Rocket, add its role ARN
#    to product_sqs_writer_arns in the same env_config block.
#
# ============================================================================

# ----------------------------------------------------------------------------
# EVENT BUS
# ----------------------------------------------------------------------------
# Central hub for all Rocket events.

resource "aws_cloudwatch_event_bus" "rocket" {
  name = "${local.name_prefix}-events"
  tags = local.common_tags
}

# Policy: Allow Lambda Core to publish events
resource "aws_cloudwatch_event_bus_policy" "rocket" {
  event_bus_name = aws_cloudwatch_event_bus.rocket.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRocketCorePublish"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_core.role_arn
        }
        Action   = "events:PutEvents"
        Resource = aws_cloudwatch_event_bus.rocket.arn
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# EVENT ARCHIVE
# ----------------------------------------------------------------------------
# Keep events for debugging and replay.

resource "aws_cloudwatch_event_archive" "rocket" {
  name             = "${local.name_prefix}-events-archive"
  event_source_arn = aws_cloudwatch_event_bus.rocket.arn
  description      = "Archive of all Rocket events for replay"
  retention_days   = local.config.eventbridge_archive_days
}

# ----------------------------------------------------------------------------
# DEAD LETTER QUEUE
# ----------------------------------------------------------------------------
# Captures events that fail delivery to product buses.

module "sqs_eventbridge_dlq" {
  source = "../shared/modules/sqs-queue"

  name                       = "${local.name_prefix}-eventbridge-dlq"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600 # 14 days
  enable_dlq                 = false   # DLQ doesn't need its own DLQ
  tags                       = local.common_tags
}

# Policy: Allow EventBridge to write to DLQ
resource "aws_sqs_queue_policy" "eventbridge_dlq" {
  queue_url = module.sqs_eventbridge_dlq.queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = module.sqs_eventbridge_dlq.queue_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_bus.rocket.arn
          }
        }
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# IAM ROLE FOR EVENTBRIDGE
# ----------------------------------------------------------------------------
# Allows EventBridge to forward events to product buses.

resource "aws_iam_role" "eventbridge_forward" {
  name = "${local.name_prefix}-eventbridge-forward-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "eventbridge_forward" {
  name = "${local.name_prefix}-eventbridge-forward-policy"
  role = aws_iam_role.eventbridge_forward.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "events:PutEvents"
        Resource = "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:event-bus/*"
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.sqs_eventbridge_dlq.queue_arn
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# IAM ROLE FOR EVENTBRIDGE SCHEDULER
# ----------------------------------------------------------------------------
# Used by EventBridge Scheduler to send messages to SQS inbound queue.
# Core creates one-time schedules for tier consolidation before Stripe renewal.

resource "aws_iam_role" "scheduler_sqs" {
  name = "${local.name_prefix}-scheduler-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "scheduler_sqs" {
  name = "${local.name_prefix}-scheduler-sqs-policy"
  role = aws_iam_role.scheduler_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.sqs_inbound.queue_arn
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# PENDING OPERATIONS SWEEP
# ----------------------------------------------------------------------------
# Every pending operation has its own one-time schedule, created by Core.
# This recurring one sends again those whose schedule never fired (not
# created, or Core stopped before the first sending).

resource "aws_scheduler_schedule" "pending_operations_sweep" {
  name                = "${local.name_prefix}-pending-operations-sweep"
  schedule_expression = "rate(15 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.sqs_inbound.queue_arn
    role_arn = aws_iam_role.scheduler_sqs.arn
    input = jsonencode({
      productId  = "rocket"
      operation  = "UPDATE"
      entityType = "PENDING_OPERATION_SWEEP"
      payload    = [{}]
    })
  }
}

# ----------------------------------------------------------------------------
# DUE DATES OF THE CUSTOMERS OF THE RESELLERS
# ----------------------------------------------------------------------------
# Every morning Core reminds each reseller, in one email, of the due dates of
# its customers still open: the ones of the day and the ones 5 and 10 days late.

resource "aws_scheduler_schedule" "customer_dues_digest" {
  name                         = "${local.name_prefix}-customer-dues-digest"
  schedule_expression          = "cron(0 8 * * ? *)"
  schedule_expression_timezone = "Europe/Rome"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.sqs_inbound.queue_arn
    role_arn = aws_iam_role.scheduler_sqs.arn
    input = jsonencode({
      productId  = "rocket"
      operation  = "UPDATE"
      entityType = "CUSTOMER_DUES_DIGEST"
      payload    = [{}]
    })
  }
}

# ----------------------------------------------------------------------------
# ORDERS PAST THEIR DELIVERY DATE
# ----------------------------------------------------------------------------
# Every morning Core tells the Keus back office of the confirmed orders past
# their delivery date with lines still to provision, once per order.

resource "aws_scheduler_schedule" "order_overdue_check" {
  name                         = "${local.name_prefix}-order-overdue-check"
  schedule_expression          = "cron(0 8 * * ? *)"
  schedule_expression_timezone = "Europe/Rome"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.sqs_inbound.queue_arn
    role_arn = aws_iam_role.scheduler_sqs.arn
    input = jsonencode({
      productId  = "rocket"
      operation  = "UPDATE"
      entityType = "ORDER_OVERDUE_CHECK"
      payload    = [{}]
    })
  }
}

# ----------------------------------------------------------------------------
# METRICS OF THE CURRENT MONTH
# ----------------------------------------------------------------------------
# Every night Core recalculates the dashboard metrics of the current month, so a
# month nobody opens a dashboard in still gets its figures. The month is the UTC
# one, as Core computes it: the last run of a month closes that month.

resource "aws_scheduler_schedule" "metrics_refresh" {
  name                         = "${local.name_prefix}-metrics-refresh"
  schedule_expression          = "cron(50 23 * * ? *)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.sqs_inbound.queue_arn
    role_arn = aws_iam_role.scheduler_sqs.arn
    input = jsonencode({
      productId  = "rocket"
      operation  = "UPDATE"
      entityType = "METRICS_REFRESH"
      payload    = [{}]
    })
  }
}

# ----------------------------------------------------------------------------
# HEALTH OF THE PRODUCTS
# ----------------------------------------------------------------------------
# Every 15 minutes Core calls the health address of each product and records
# its outages, for the availability of the technical metrics. An outage shorter
# than the interval may not appear.

resource "aws_scheduler_schedule" "health_check" {
  name                = "${local.name_prefix}-health-check"
  schedule_expression = "rate(15 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.sqs_inbound.queue_arn
    role_arn = aws_iam_role.scheduler_sqs.arn
    input = jsonencode({
      productId  = "rocket"
      operation  = "UPDATE"
      entityType = "HEALTH_CHECK"
      payload    = [{}]
    })
  }
}

# ----------------------------------------------------------------------------
# EVENT RULES AND TARGETS (per product)
# ----------------------------------------------------------------------------
# One rule per product. Events are forwarded to the product's own EventBridge bus.
# The product handles internal routing to its microservices.

resource "aws_cloudwatch_event_rule" "products" {
  for_each = {
    for k, v in local.config.products_config : k => v
    if v.enabled
  }

  name           = "${local.name_prefix}-${each.key}-rule"
  description    = "Forward events to ${each.key} bus"
  event_bus_name = aws_cloudwatch_event_bus.rocket.name

  event_pattern = jsonencode({
    source      = ["rocket"]
    detail-type = ["rocket-notification"]
    detail = {
      productId = [each.value.product_id]
    }
  })

  state = "ENABLED"
  tags  = merge(local.common_tags, { ProductId = each.value.product_id })
}

resource "aws_cloudwatch_event_target" "products" {
  for_each = {
    for k, v in local.config.products_config : k => v
    if v.enabled
  }

  rule           = aws_cloudwatch_event_rule.products[each.key].name
  event_bus_name = aws_cloudwatch_event_bus.rocket.name
  target_id      = "${each.key}-bus"
  arn            = each.value.event_bus_arn
  role_arn       = aws_iam_role.eventbridge_forward.arn

  dead_letter_config {
    arn = module.sqs_eventbridge_dlq.queue_arn
  }
}
