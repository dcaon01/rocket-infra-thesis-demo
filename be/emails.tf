# ============================================================================
# EMAILS - ROCKET BRANDED TEMPLATES
# ============================================================================
# Every email Rocket sends is defined here, wrapped in the same brand frame
# (templates/email/layout.html.tftpl):
# - the Cognito invite and verification code, set on the user pool (cognito.tf);
# - the communications to resellers and Keus staff, published as SES templates
#   and sent by the core with MailService.
# Communications to end customers are not here: products send them.
# ============================================================================

# ----------------------------------------------------------------------------
# PUBLIC IMAGES
# ----------------------------------------------------------------------------
# Email clients need images at a public URL: Gmail drops inline base64. A
# dedicated public bucket that holds only these images, because the FE bucket
# is synced with --delete on deploy.
#
# The public read is deliberate and covers every object: put nothing here that
# is not meant for the open internet. ACLs stay disabled, so the policy below is
# the only way in.
# ----------------------------------------------------------------------------

resource "aws_s3_bucket" "email_assets" {
  bucket = "${local.name_prefix}-email-assets"

  tags = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "email_assets" {
  bucket = aws_s3_bucket.email_assets.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "email_assets" {
  bucket = aws_s3_bucket.email_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "email_assets" {
  bucket = aws_s3_bucket.email_assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "email_assets_public_read" {
  statement {
    sid       = "PublicReadEmailImages"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.email_assets.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "email_assets" {
  bucket = aws_s3_bucket.email_assets.id
  policy = data.aws_iam_policy_document.email_assets_public_read.json

  # The bucket settles before it opens, and the targeted apply reaches them through here.
  depends_on = [
    aws_s3_bucket_public_access_block.email_assets,
    aws_s3_bucket_ownership_controls.email_assets,
    aws_s3_bucket_server_side_encryption_configuration.email_assets,
  ]
}

resource "aws_s3_object" "email_assets" {
  for_each = fileset("${path.module}/templates/email/assets", "*.png")

  bucket        = aws_s3_bucket.email_assets.id
  key           = each.value
  source        = "${path.module}/templates/email/assets/${each.value}"
  etag          = filemd5("${path.module}/templates/email/assets/${each.value}")
  content_type  = "image/png"
  cache_control = "public, max-age=86400"
}

# ----------------------------------------------------------------------------
# RENDERING
# ----------------------------------------------------------------------------
# Terraform fills ${...}; Cognito's {username} and {####} and SES's {{...}} pass
# through untouched and are filled at send time.
# ----------------------------------------------------------------------------

locals {
  email_templates_dir = "${path.module}/templates/email"
  email_asset_base    = "https://${aws_s3_bucket.email_assets.bucket_regional_domain_name}"

  # Attributes of the cell of a button: the Keus primary, a plain colour every client paints.
  email_button_cell = "bgcolor=\"#0A0300\" style=\"border-radius:8px;background-color:#0A0300;\""

  cognito_invite_email = templatefile("${local.email_templates_dir}/layout.html.tftpl", {
    asset_base_url = local.email_asset_base
    content = templatefile("${local.email_templates_dir}/cognito-invite.html.tftpl", {
      login_url              = local.login_url
      password_validity_days = local.temporary_password_validity_days
      button_cell            = local.email_button_cell
    })
  })

  cognito_verification_email = templatefile("${local.email_templates_dir}/layout.html.tftpl", {
    asset_base_url = local.email_asset_base
    content        = file("${local.email_templates_dir}/cognito-verification.html.tftpl")
  })

  # Communications sent by the core: the key is the template name MailService uses.
  # SES does not escape: MailService escapes the values for the HTML part and adds the
  # raw ones under `text`, which the subject and the plain-text part must read.
  core_emails = {
    "order-accepted"          = { subject = "Ordine {{text.orderCode}}: da confermare" }
    "order-submitted"         = { subject = "Ordine {{text.orderCode}} inviato a Keus" }
    "order-confirmed"         = { subject = "Ordine {{text.orderCode}} confermato" }
    "order-overdue"           = { subject = "Ordine {{text.orderCode}}: consegna in ritardo" }
    "line-provisioned"        = { subject = "Ordine {{text.orderCode}}: {{text.productName}} erogato" }
    "quote-requested"         = { subject = "Ordine {{text.orderCode}}: personalizzazioni da quotare" }
    "quotation-saved"         = { subject = "Ordine {{text.orderCode}}: quotazione pronta" }
    "approval-requested"      = { subject = "Ordine {{text.orderCode}}: offerta da approvare" }
    "approval-granted"        = { subject = "Ordine {{text.orderCode}}: offerta approvata" }
    "approval-refused"        = { subject = "Ordine {{text.orderCode}}: offerta non approvata" }
    "payment-failed"          = { subject = "Addebito non riuscito: {{text.partyName}}" }
    "payment-disputed"        = { subject = "Contestazione dell'addebito: {{text.partyName}}" }
    "payment-refunded"        = { subject = "Rimborso registrato: {{text.partyName}}" }
    "mandate-revoked"         = { subject = "Mandato SEPA revocato: {{text.customerName}}" }
    "payment-reminder"        = { subject = "Sollecito di pagamento, fattura del {{text.issuedAt}}" }
    "payment-reminder-admin"  = { subject = "Sollecito inviato: {{text.partyName}}" }
    "suspension-notice-admin" = { subject = "Preavviso di sospensione inviato: {{text.companyName}}" }
    "access-suspended"        = { subject = "Accessi sospesi: {{text.companyName}}, {{text.productName}}" }
    "access-restored"         = { subject = "Accessi riattivati: {{text.companyName}}, {{text.productName}}" }
    "seat-variation"          = { subject = "Contratto {{text.contractCode}}: variazione delle postazioni" }
    "renewal-notice"          = { subject = "Contratto {{text.contractCode}}: rinnovo il {{text.renewalDate}}" }
    "customer-dues"           = { subject = "Scadenze dei clienti da incassare" }
    "reseller-pro-forma"      = { subject = "Contratto {{text.contractCode}}: pro forma" }

    # The block of a reseller in Rocket for an unpaid invoice: to the reseller and to the Keus administration.
    "reseller-suspension-notice"       = { subject = "Preavviso di blocco di Rocket, fattura del {{text.issuedAt}}" }
    "reseller-access-suspended"        = { subject = "Accesso a Rocket bloccato" }
    "reseller-access-restored"         = { subject = "Accesso a Rocket riattivato" }
    "reseller-suspension-notice-admin" = { subject = "Preavviso di blocco inviato: {{text.partyName}}" }
    "reseller-access-suspended-admin"  = { subject = "Rivenditore bloccato: {{text.partyName}}" }
    "reseller-access-restored-admin"   = { subject = "Rivenditore riattivato: {{text.partyName}}" }

    # To the companies, about their orders and contracts: the products only write about their own logic and the trials.
    "company-payment-setup-reminder" = { subject = "{{text.productName}}: pagamento da attivare" }
    "company-payment-reminder"       = { subject = "{{text.productName}}: sollecito di pagamento" }
    "company-suspension-notice"      = { subject = "{{text.productName}}: preavviso di sospensione degli accessi" }
    "company-access-suspended"       = { subject = "{{text.productName}}: accessi sospesi" }
    "company-access-restored"        = { subject = "{{text.productName}}: accessi riattivati" }
    "company-seat-variation"         = { subject = "{{text.productName}}: variazione delle postazioni" }
    "company-renewal-notice"         = { subject = "{{text.productName}}: il contratto si rinnova il {{text.renewalDate}}" }
    "company-contract-accepted"      = { subject = "{{text.productName}}: contratto {{text.contractCode}} sottoscritto" }
  }
}

# Published as <name_prefix>-<key>: the core reads MAIL_TEMPLATE_PREFIX to find them.
resource "aws_ses_template" "core" {
  for_each = local.core_emails

  name    = "${local.name_prefix}-${each.key}"
  subject = each.value.subject
  html = templatefile("${local.email_templates_dir}/layout.html.tftpl", {
    asset_base_url = local.email_asset_base
    content = templatefile("${local.email_templates_dir}/${each.key}.html.tftpl", {
      button_cell = local.email_button_cell
    })
  })
  text = file("${local.email_templates_dir}/${each.key}.txt.tftpl")
}
