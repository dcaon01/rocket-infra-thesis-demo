# ============================================================================
# DATA SOURCES - ROCKET FRONTEND INFRASTRUCTURE
# ============================================================================

# Current AWS caller identity
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}
