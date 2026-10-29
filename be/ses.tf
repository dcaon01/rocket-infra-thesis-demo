# ============================================================================
# SES - ROCKET SENDING IDENTITY
# ============================================================================
# One domain identity per environment, on the domain the FE is served on:
# rockettino.keus.dev (dev) and rocket.keus.dev (prod). Every Rocket email
# leaves from noreply@<that domain>: the Cognito invite and verification code,
# and the communications the core sends to resellers and Keus staff.
#
# Both domains are CNAMEs to CloudFront, so no record can sit on them: DKIM and
# MAIL FROM live on sub-names (<token>._domainkey.<domain>, bounce.<domain>).
# The keus.dev identity already in this region was created by hand and is left
# alone.
# ============================================================================

# Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
# The demo sends no email: the identity, its records and the zone of keus.dev exist only with the integrations on.
data "aws_route53_zone" "keus" {
  count = var.integrations_enabled ? 1 : 0

  name         = "${local.mail_dns_zone}."
  private_zone = false
}

resource "aws_sesv2_email_identity" "rocket" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  email_identity = local.config.domain_name

  tags = local.common_tags
}

# Easy DKIM, three CNAMEs named after the identity's own tokens.
resource "aws_route53_record" "ses_dkim" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 3 : 0

  zone_id = data.aws_route53_zone.keus[0].zone_id
  name    = "${aws_sesv2_email_identity.rocket[0].dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.config.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_sesv2_email_identity.rocket[0].dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

# ----------------------------------------------------------------------------
# CUSTOM MAIL FROM
# ----------------------------------------------------------------------------
# Moves the envelope sender off amazonses.com, so SPF aligns with our domain and
# Gmail stops showing "via amazonses.com". USE_DEFAULT_VALUE keeps mail flowing
# if the MX ever stops resolving.
# ----------------------------------------------------------------------------

resource "aws_sesv2_email_identity_mail_from_attributes" "rocket" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  email_identity         = aws_sesv2_email_identity.rocket[0].email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

resource "aws_route53_record" "ses_mail_from_mx" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.keus[0].zone_id
  name    = local.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

resource "aws_route53_record" "ses_mail_from_spf" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.keus[0].zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# ----------------------------------------------------------------------------
# SENDING AUTHORIZATION FOR COGNITO
# ----------------------------------------------------------------------------
# Cognito sends as a separate principal and needs the identity's permission.
# The identity is per environment, so the policy names this environment's pool.
# ----------------------------------------------------------------------------

data "aws_iam_policy_document" "ses_cognito" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  statement {
    sid    = "AllowCognitoUserPoolToSend"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["email.cognito-idp.amazonaws.com"]
    }

    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = [aws_sesv2_email_identity.rocket[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.cognito.user_pool_arn]
    }
  }
}

resource "aws_ses_identity_policy" "cognito" {
  # Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.
  count = var.integrations_enabled ? 1 : 0

  identity = aws_sesv2_email_identity.rocket[0].arn
  name     = "${local.name_prefix}-cognito-send"
  policy   = data.aws_iam_policy_document.ses_cognito[0].json
}
