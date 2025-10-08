terraform {
  required_version = ">= 1.0.0"
}

locals {
  # Only set aws_role_arn if both aws_account_id and aws_role_name are provided
  aws_role_arn = var.aws_account_id != null && var.aws_role_name != null ? "arn:aws:iam::${var.aws_account_id}:role/${var.aws_role_name}" : null
}

module "network" {
  source = "./modules/network"

  aws_region     = var.aws_region
  aws_role_arn   = local.aws_role_arn
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

module "ecs" {
  source = "./modules/ecs"

  # AWS provider
  aws_region   = var.aws_region
  aws_role_arn = local.aws_role_arn

  # Network configuration from network module
  vpc_id                  = module.network.vpc_id
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  private_route_table_ids = module.network.private_route_table_ids

  # Get certificate from ACM module
  acm_certificate_arn = module.network.acm_certificate_arn

  # DNS
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id

  # Tracecat version
  tracecat_image            = var.tracecat_image
  tracecat_ui_image         = var.tracecat_ui_image
  tracecat_image_tag        = var.tracecat_image_tag
  temporal_server_image     = var.temporal_server_image
  temporal_server_image_tag = var.temporal_server_image_tag
  temporal_ui_image         = var.temporal_ui_image
  temporal_ui_image_tag     = var.temporal_ui_image_tag
  force_new_deployment      = var.force_new_deployment

  # Temporal configuration
  disable_temporal_ui        = var.disable_temporal_ui
  disable_temporal_autosetup = var.disable_temporal_autosetup
  temporal_cluster_url       = var.temporal_cluster_url
  temporal_cluster_queue     = var.temporal_cluster_queue
  temporal_namespace         = var.temporal_namespace
  temporal_task_timeout      = var.temporal_task_timeout

  # Container environment variables
  tracecat_app_env                 = var.tracecat_app_env
  log_level                        = var.log_level
  temporal_log_level               = var.temporal_log_level
  context_compression_enabled      = var.context_compression_enabled
  context_compression_threshold_kb = var.context_compression_threshold_kb

  # Database connection pool
  db_max_overflow          = var.db_max_overflow
  db_pool_size             = var.db_pool_size
  db_pool_timeout          = var.db_pool_timeout
  db_pool_recycle          = var.db_pool_recycle
  db_max_overflow_executor = var.db_max_overflow_executor
  db_pool_size_executor    = var.db_pool_size_executor

  # RDS settings
  restore_from_snapshot            = var.restore_from_snapshot
  rds_backup_retention_period      = var.rds_backup_retention_period
  rds_performance_insights_enabled = var.rds_performance_insights_enabled
  rds_database_insights_mode       = var.rds_database_insights_mode
  core_db_snapshot_name            = var.core_db_snapshot_name
  temporal_db_snapshot_name        = var.temporal_db_snapshot_name

  # Custom integrations
  remote_repository_package_name = var.remote_repository_package_name
  remote_repository_url          = var.remote_repository_url

  # Secrets from AWS Secrets Manager
  tracecat_db_encryption_key_arn = var.tracecat_db_encryption_key_arn
  tracecat_service_key_arn       = var.tracecat_service_key_arn
  tracecat_signing_secret_arn    = var.tracecat_signing_secret_arn
  langfuse_credentials_arn       = var.langfuse_credentials_arn

  # Authentication
  auth_types            = var.auth_types
  auth_allowed_domains  = var.auth_allowed_domains
  auth_superadmin_email = var.auth_superadmin_email

  # OAuth
  oauth_client_id_arn     = var.oauth_client_id_arn
  oauth_client_secret_arn = var.oauth_client_secret_arn

  # SAML SSO
  saml_idp_metadata_url_arn = var.saml_idp_metadata_url_arn

  # Temporal UI authentication
  temporal_auth_provider_url      = var.temporal_auth_provider_url
  temporal_auth_client_id_arn     = var.temporal_auth_client_id_arn
  temporal_auth_client_secret_arn = var.temporal_auth_client_secret_arn

  # Temporal client authentication
  temporal_api_key_arn = var.temporal_api_key_arn

  # Compute / memory
  api_cpu                         = var.api_cpu
  api_memory                      = var.api_memory
  worker_cpu                      = var.worker_cpu
  worker_memory                   = var.worker_memory
  worker_desired_count            = var.worker_desired_count
  executor_cpu                    = var.executor_cpu
  executor_memory                 = var.executor_memory
  executor_client_timeout         = var.executor_client_timeout
  executor_payload_max_size_bytes = var.executor_payload_max_size_bytes
  ui_cpu                          = var.ui_cpu
  ui_memory                       = var.ui_memory
  temporal_cpu                    = var.temporal_cpu
  temporal_memory                 = var.temporal_memory
  temporal_client_rpc_timeout     = var.temporal_client_rpc_timeout
  temporal_num_history_shards     = var.temporal_num_history_shards
  caddy_cpu                       = var.caddy_cpu
  caddy_memory                    = var.caddy_memory
  db_instance_class               = var.db_instance_class
  db_instance_size                = var.db_instance_size
  db_allocated_storage            = var.db_allocated_storage

  # Metrics configuration
  enable_metrics             = var.enable_metrics
  metrics_auth_username      = var.metrics_auth_username
  metrics_auth_password_hash = var.metrics_auth_password_hash

  # Sentry configuration
  sentry_dsn = var.sentry_dsn
}
