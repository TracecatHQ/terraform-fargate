# Required secrets in AWS Secrets Manager:
# 1. TRACECAT__DB_ENCRYPTION_KEY
# 2. TRACECAT__SERVICE_KEY
# 3. TRACECAT__SIGNING_SECRET
#
# Optional secrets:
# 1. OAUTH_CLIENT_ID
# 2. OAUTH_CLIENT_SECRET
# 3. Langfuse credentials (LANGFUSE_SECRET_KEY, LANGFUSE_PUBLIC_KEY, LANGFUSE_HOST)

### Required secrets
data "aws_secretsmanager_secret" "tracecat_db_encryption_key" {
  arn = var.tracecat_db_encryption_key_arn
}

data "aws_secretsmanager_secret" "tracecat_service_key" {
  arn = var.tracecat_service_key_arn
}

data "aws_secretsmanager_secret" "tracecat_signing_secret" {
  arn = var.tracecat_signing_secret_arn
}

### Optional secrets

# Tracecat authentication

data "aws_secretsmanager_secret" "oauth_client_id" {
  count = var.oauth_client_id_arn != null ? 1 : 0
  arn   = var.oauth_client_id_arn
}

data "aws_secretsmanager_secret" "oauth_client_secret" {
  count = var.oauth_client_secret_arn != null ? 1 : 0
  arn   = var.oauth_client_secret_arn
}

data "aws_secretsmanager_secret" "saml_idp_metadata_url" {
  count = var.saml_idp_metadata_url_arn != null ? 1 : 0
  arn   = var.saml_idp_metadata_url_arn
}

# Temporal UI authentication

data "aws_secretsmanager_secret" "temporal_auth_client_id" {
  count = var.temporal_auth_client_id_arn != null ? 1 : 0
  arn   = var.temporal_auth_client_id_arn
}

data "aws_secretsmanager_secret" "temporal_auth_client_secret" {
  count = var.temporal_auth_client_secret_arn != null ? 1 : 0
  arn   = var.temporal_auth_client_secret_arn
}

# Langfuse credentials
data "aws_secretsmanager_secret" "langfuse_credentials" {
  count = var.langfuse_credentials_arn != null ? 1 : 0
  arn   = var.langfuse_credentials_arn
}

### Retrieve secret values

# Tracecat secrets

data "aws_secretsmanager_secret_version" "tracecat_db_encryption_key" {
  secret_id = data.aws_secretsmanager_secret.tracecat_db_encryption_key.id
}

data "aws_secretsmanager_secret_version" "tracecat_service_key" {
  secret_id = data.aws_secretsmanager_secret.tracecat_service_key.id
}

data "aws_secretsmanager_secret_version" "tracecat_signing_secret" {
  secret_id = data.aws_secretsmanager_secret.tracecat_signing_secret.id
}

data "aws_secretsmanager_secret_version" "oauth_client_id" {
  count     = var.oauth_client_id_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.oauth_client_id[0].id
}

data "aws_secretsmanager_secret_version" "oauth_client_secret" {
  count     = var.oauth_client_secret_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.oauth_client_secret[0].id
}

data "aws_secretsmanager_secret_version" "saml_idp_metadata_url" {
  count     = var.saml_idp_metadata_url_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.saml_idp_metadata_url[0].id
}

# Temporal UI secrets

data "aws_secretsmanager_secret_version" "temporal_auth_client_id" {
  count     = var.temporal_auth_client_id_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.temporal_auth_client_id[0].id
}

data "aws_secretsmanager_secret_version" "temporal_auth_client_secret" {
  count     = var.temporal_auth_client_secret_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.temporal_auth_client_secret[0].id
}

data "aws_secretsmanager_secret_version" "langfuse_credentials" {
  count     = var.langfuse_credentials_arn != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.langfuse_credentials[0].id
}

### Database secrets

data "aws_secretsmanager_secret" "tracecat_db_password" {
  arn        = aws_db_instance.core_database.master_user_secret[0].secret_arn
  depends_on = [aws_db_instance.core_database]
}

data "aws_secretsmanager_secret" "temporal_db_password" {
  count      = var.disable_temporal_autosetup ? 0 : 1
  arn        = aws_db_instance.temporal_database[0].master_user_secret[0].secret_arn
  depends_on = [aws_db_instance.temporal_database]
}

data "aws_secretsmanager_secret_version" "tracecat_db_password" {
  secret_id = data.aws_secretsmanager_secret.tracecat_db_password.id
}

data "aws_secretsmanager_secret_version" "temporal_db_password" {
  count     = var.disable_temporal_autosetup ? 0 : 1
  secret_id = data.aws_secretsmanager_secret.temporal_db_password[0].id
}

locals {
  tracecat_base_secrets = [
    {
      name      = "TRACECAT__SERVICE_KEY"
      valueFrom = data.aws_secretsmanager_secret_version.tracecat_service_key.arn
    },
    {
      name      = "TRACECAT__SIGNING_SECRET"
      valueFrom = data.aws_secretsmanager_secret_version.tracecat_signing_secret.arn
    },
    {
      name      = "TRACECAT__DB_ENCRYPTION_KEY"
      valueFrom = data.aws_secretsmanager_secret_version.tracecat_db_encryption_key.arn
    },
  ]

  oauth_client_id_secret = var.oauth_client_id_arn != null ? [
    {
      name      = "OAUTH_CLIENT_ID"
      valueFrom = data.aws_secretsmanager_secret_version.oauth_client_id[0].arn
    }
  ] : []

  oauth_client_secret_secret = var.oauth_client_secret_arn != null ? [
    {
      name      = "OAUTH_CLIENT_SECRET"
      valueFrom = data.aws_secretsmanager_secret_version.oauth_client_secret[0].arn
    }
  ] : []

  saml_idp_metadata_url_secret = var.saml_idp_metadata_url_arn != null ? [
    {
      name      = "SAML_IDP_METADATA_URL"
      valueFrom = data.aws_secretsmanager_secret_version.saml_idp_metadata_url[0].arn
    }
  ] : []

  temporal_auth_client_id_secret = var.temporal_auth_client_id_arn != null ? [
    {
      name      = "TEMPORAL_AUTH_CLIENT_ID"
      valueFrom = data.aws_secretsmanager_secret_version.temporal_auth_client_id[0].arn
    }
  ] : []

  temporal_auth_client_secret_secret = var.temporal_auth_client_secret_arn != null ? [
    {
      name      = "TEMPORAL_AUTH_CLIENT_SECRET"
      valueFrom = data.aws_secretsmanager_secret_version.temporal_auth_client_secret[0].arn
    }
  ] : []

  tracecat_api_secrets = concat(
    local.tracecat_base_secrets,
    local.oauth_client_id_secret,
    local.oauth_client_secret_secret,
    local.saml_idp_metadata_url_secret
  )

  tracecat_ui_secrets = [
    {
      name      = "TRACECAT__SERVICE_KEY"
      valueFrom = data.aws_secretsmanager_secret_version.tracecat_service_key.arn
    }
  ]

  temporal_secrets = var.disable_temporal_autosetup ? [] : [
    {
      name      = "POSTGRES_PWD"
      valueFrom = "${data.aws_secretsmanager_secret_version.temporal_db_password[0].arn}:password::"
    }
  ]

  temporal_ui_secrets = concat(
    local.temporal_auth_client_id_secret,
    local.temporal_auth_client_secret_secret,
  )

  langfuse_credentials_secret = var.langfuse_credentials_arn != null ? [
    {
      name      = "LANGFUSE_SECRET_KEY"
      valueFrom = "${data.aws_secretsmanager_secret_version.langfuse_credentials[0].arn}:LANGFUSE_SECRET_KEY::"
    },
    {
      name      = "LANGFUSE_PUBLIC_KEY"
      valueFrom = "${data.aws_secretsmanager_secret_version.langfuse_credentials[0].arn}:LANGFUSE_PUBLIC_KEY::"
    },
    {
      name      = "LANGFUSE_HOST"
      valueFrom = "${data.aws_secretsmanager_secret_version.langfuse_credentials[0].arn}:LANGFUSE_HOST::"
    }
  ] : []

  executor_secrets = concat(
    local.tracecat_base_secrets,
    local.langfuse_credentials_secret,
  )
}
