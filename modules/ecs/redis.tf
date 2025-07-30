# subnet group (or use an existing one from your network module)
resource "aws_elasticache_subnet_group" "redis" {
  name       = "tracecat-redis-subnet"
  subnet_ids = var.private_subnet_ids
}

# Default user (required by AWS ElastiCache)
resource "aws_elasticache_user" "default" {
  user_id       = "default-user-tracecat"
  user_name     = "default"  # Must be named "default"
  engine        = "REDIS"
  access_string = "off ~* -@all"  # Disabled user with no access
  authentication_mode {
    type = "no-password-required"
  }
}

# IAM-auth user + user-group
resource "aws_elasticache_user" "iam_user" {
  user_id       = "tracecat-iam-user"
  user_name     = "tracecat-iam-user"  # Must match user_id for IAM auth
  engine        = "REDIS"
  access_string = "on ~* +@all"
  authentication_mode { type = "iam" }
}

resource "aws_elasticache_user_group" "redis" {
  user_group_id = "tracecat-users"
  engine        = "REDIS"
  user_ids      = [
    aws_elasticache_user.default.user_id,
    aws_elasticache_user.iam_user.user_id
  ]
}

# The replication group (single-node, TLS & KMS encryption are ON by default in Redis 7)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "tracecat-redis"
  description          = "Tracecat Redis - IAM auth"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type # default cache.t3.micro
  num_cache_clusters   = 1                   # single AZ, no failover
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  user_group_ids = [aws_elasticache_user_group.redis.id]

  transit_encryption_enabled = true # always enable TLS
  at_rest_encryption_enabled = true
} 