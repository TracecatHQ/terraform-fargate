output "tracecat_image_tag" {
  description = "The version of Tracecat used"
  value       = local.tracecat_image_tag
}

output "public_app_url" {
  description = "The public URL of the app"
  value       = local.public_app_url
}

output "public_api_url" {
  description = "The public URL of the API"
  value       = local.public_api_url
}

output "internal_api_url" {
  description = "The internal URL of the API"
  value       = local.internal_api_url
}

output "allow_origins" {
  description = "The allowed origins for CORS"
  value       = local.allow_origins
}

output "local_dns_namespace" {
  description = "The local DNS namespace for ECS services"
  value       = local.local_dns_namespace
}

# Outputs

output "latest_core_snapshot_encrypted" {
  value       = var.restore_from_snapshot && var.core_db_snapshot_name == null ? try(data.aws_db_snapshot.core_snapshots[0].encrypted, null) : null
  description = "Whether the latest core database snapshot is encrypted (only available when using automatic snapshot selection)"
}

output "latest_temporal_snapshot_encrypted" {
  value       = var.restore_from_snapshot && var.temporal_db_snapshot_name == null && !var.disable_temporal_autosetup ? try(data.aws_db_snapshot.temporal_snapshots[0].encrypted, null) : null
  description = "Whether the latest temporal database snapshot is encrypted (only available when using automatic snapshot selection)"
}

output "s3_attachments_bucket_name" {
  value       = aws_s3_bucket.attachments.bucket
  description = "The name of the S3 bucket used for attachments storage"
}

output "s3_attachments_bucket_arn" {
  value       = aws_s3_bucket.attachments.arn
  description = "The ARN of the S3 bucket used for attachments storage"
}
