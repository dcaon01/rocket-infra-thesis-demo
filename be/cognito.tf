# ============================================================================
# COGNITO USER POOL - ROCKET AUTHENTICATION
# ============================================================================
# AWS Cognito handles user authentication:
# - User signup/signin
# - Password policies
# - JWT token generation
# - MFA (optional)
#
# B2B setup: Only admins can create users (allow_admin_create_user_only = true)
# ============================================================================

module "cognito" {
  source = "../shared/modules/cognito"

  # Basic configuration
  name        = "${local.name_prefix}-user-pool"
  environment = local.environment

  # Password policy (strong but usable)
  password_minimum_length          = 8
  password_require_lowercase       = true
  password_require_numbers         = true
  password_require_symbols         = true
  password_require_uppercase       = true
  temporary_password_validity_days = local.temporary_password_validity_days

  # MFA optional, admin-only signup (B2B)
  mfa_configuration            = "OPTIONAL"
  allow_admin_create_user_only = true

  # Branded HTML emails (emails.tf). The verification one also carries the
  # password reset code, hence its generic wording.
  email_verification_subject = "Il tuo codice Rocket"
  email_verification_message = local.cognito_verification_email
  invite_email_subject       = "Benvenuto in Rocket"
  invite_email_message       = local.cognito_invite_email

  # Sent through SES from noreply@<domain> once the identity is verified (ses.tf).
  # Cognito rejects an unverified identity, so the first apply keeps the default
  # sender and the next one, after DKIM succeeds, switches to SES.
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  # Without the identity (the demo) Cognito sends its invites from its own address.
  ses_identity_arn   = try(aws_sesv2_email_identity.rocket[0].verified_for_sending_status ? aws_sesv2_email_identity.rocket[0].arn : null, null)
  from_email_address = local.mail_from

  # Custom user attributes (appear as custom:attributeName in JWT)
  custom_attributes = [
    { name = "profilePicS3Key", type = "String", max_length = 512 },
    { name = "companyRole", type = "String", max_length = 100 },
    { name = "gender", type = "String", max_length = 20 },
    { name = "tenantId", type = "String", max_length = 36 },
    # Reseller the user belongs to. Read from the JWT by the backend ScopeGuard
    # to restrict a reseller user to its own perimeter.
    { name = "resellerCode", type = "String", max_length = 64 }
  ]

  # App client configuration - token validity
  client_name            = "${local.name_prefix}-web-client"
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour
  refresh_token_validity = 30 # 30 days

  # User groups for authorization
  groups = [
    # Account type: where the user works. Mutually exclusive, enforced app-side.
    { name = "collaborator", description = "Works at Keus: sees every product, channel and reseller", precedence = 1 },
    { name = "reseller", description = "Works at a reseller: sees only its own perimeter", precedence = 1 },

    # Profile: what the user can do on the data it sees. The prefix must match
    # the account type: keus_* only on collaborator accounts, reseller_* only on
    # reseller ones. The backend RolesGuard rejects any mismatch.
    { name = "keus_admin", description = "Keus administrator: the only profile that configures the platform", precedence = 1 },
    { name = "keus_sales", description = "Keus sales: order requests, offers, companies, own resellers", precedence = 10 },
    { name = "keus_backoffice", description = "Keus back office: order confirmation, delivery, users, product data", precedence = 10 },
    { name = "keus_accounting", description = "Keus accounting: invoices, payment schedule, dunning, suspensions", precedence = 10 },
    { name = "reseller_owner", description = "Reseller owner: the whole perimeter of its own reseller", precedence = 5 },
    { name = "reseller_backoffice", description = "Reseller back office: every order and company of its own reseller", precedence = 10 },
    { name = "reseller_sales", description = "Reseller sales: only the orders and companies it owns", precedence = 10 }
  ]

  tags = local.common_tags
}
