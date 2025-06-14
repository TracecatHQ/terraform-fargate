# Tracecat and Temporal Environment Variables
locals {

  # Tracecat version
  tracecat_image_tag = var.tracecat_image_tag

  # Tracecat common URLs
  public_app_url         = "https://${var.domain_name}"
  public_api_url         = "https://${var.domain_name}/api"
  internal_api_url       = "http://api-service:8000"      # Service connect DNS name
  internal_executor_url  = "http://executor-service:8002" # Service connect DNS name
  temporal_cluster_url   = var.temporal_cluster_url
  temporal_cluster_queue = var.temporal_cluster_queue
  temporal_namespace     = var.temporal_namespace
  allow_origins          = "${var.domain_name},http://ui-service:3000" # Allow api service and public app to access the API

  # Temporal client authentication
  temporal_api_key_arn = var.temporal_api_key_arn

  # Tracecat postgres env vars
  # See: https://github.com/TracecatHQ/tracecat/blob/abd5ff/tracecat/db/engine.py#L21
  tracecat_db_configs = {
    TRACECAT__DB_USER      = "postgres"
    TRACECAT__DB_PORT      = "5432"
    TRACECAT__DB_NAME      = "postgres" # Hardcoded in RDS resource configs
    TRACECAT__DB_PASS__ARN = data.aws_secretsmanager_secret_version.tracecat_db_password.arn
  }

  api_env = [
    for k, v in merge({
      LOG_LEVEL                                       = var.log_level
      RUN_MIGRATIONS                                  = "true"
      TEMPORAL__CLIENT_RPC_TIMEOUT                    = var.temporal_client_rpc_timeout
      TEMPORAL__CLUSTER_NAMESPACE                     = local.temporal_namespace
      TEMPORAL__CLUSTER_QUEUE                         = local.temporal_cluster_queue
      TEMPORAL__CLUSTER_URL                           = local.temporal_cluster_url
      TEMPORAL__API_KEY__ARN                          = local.temporal_api_key_arn
      TRACECAT__ALLOW_ORIGINS                         = local.allow_origins
      TRACECAT__API_ROOT_PATH                         = "/api"
      TRACECAT__API_URL                               = local.internal_api_url
      TRACECAT__APP_ENV                               = var.tracecat_app_env
      TRACECAT__AUTH_ALLOWED_DOMAINS                  = var.auth_allowed_domains
      TRACECAT__AUTH_SUPERADMIN_EMAIL                 = var.auth_superadmin_email
      TRACECAT__AUTH_TYPES                            = var.auth_types
      TRACECAT__DB_ENDPOINT                           = local.core_db_hostname
      TRACECAT__EXECUTOR_URL                          = local.internal_executor_url
      TRACECAT__PUBLIC_API_URL                        = local.public_api_url
      TRACECAT__PUBLIC_APP_URL                        = local.public_app_url
    }, local.tracecat_db_configs) :
    { name = k, value = tostring(v) }
  ]

  worker_env = [
    for k, v in merge({
      LOG_LEVEL                         = var.log_level
      TEMPORAL__CLIENT_RPC_TIMEOUT      = var.temporal_client_rpc_timeout
      TEMPORAL__CLUSTER_NAMESPACE       = local.temporal_namespace
      TEMPORAL__CLUSTER_QUEUE           = local.temporal_cluster_queue
      TEMPORAL__CLUSTER_URL             = local.temporal_cluster_url
      TEMPORAL__API_KEY__ARN            = local.temporal_api_key_arn
      TRACECAT__API_ROOT_PATH           = "/api"
      TRACECAT__API_URL                 = local.internal_api_url
      TRACECAT__APP_ENV                 = var.tracecat_app_env
      TRACECAT__DB_ENDPOINT             = local.core_db_hostname
      TRACECAT__EXECUTOR_CLIENT_TIMEOUT = var.executor_client_timeout
      TRACECAT__EXECUTOR_URL            = local.internal_executor_url
      TRACECAT__PUBLIC_API_URL          = local.public_api_url
      SENTRY_DSN                        = var.sentry_dsn
    }, local.tracecat_db_configs) :
    { name = k, value = tostring(v) }
  ]

  executor_env = [
    for k, v in merge({
      LOG_LEVEL                                = var.log_level
      TRACECAT__APP_ENV                        = var.tracecat_app_env
      TRACECAT__DB_ENDPOINT                    = local.core_db_hostname
    }, local.tracecat_db_configs) :
    { name = k, value = tostring(v) }
  ]

  ui_env = [
    for k, v in {
      NEXT_PUBLIC_API_URL    = local.public_api_url
      NEXT_PUBLIC_APP_ENV    = var.tracecat_app_env
      NEXT_PUBLIC_APP_URL    = local.public_app_url
      NEXT_PUBLIC_AUTH_TYPES = var.auth_types
      NEXT_SERVER_API_URL    = local.internal_api_url
      NODE_ENV               = var.tracecat_app_env
    } :
    { name = k, value = tostring(v) }
  ]

  temporal_env = [
    for k, v in {
      DB                         = "postgres12"
      DB_PORT                    = "5432"
      POSTGRES_USER              = "postgres"
      LOG_LEVEL                  = var.temporal_log_level
      TEMPORAL_BROADCAST_ADDRESS = "0.0.0.0"
      BIND_ON_IP                 = "0.0.0.0"
      NUM_HISTORY_SHARDS         = var.temporal_num_history_shards
    } :
    { name = k, value = tostring(v) }
  ]
}
