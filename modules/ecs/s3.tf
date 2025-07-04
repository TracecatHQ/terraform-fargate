# S3 bucket for Tracecat blob storage with security hardening
resource "aws_s3_bucket" "tracecat" {
  bucket = "tracecat"
}

# Block public access completely
resource "aws_s3_bucket_public_access_block" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id

  rule {
    id     = "blob_storage_lifecycle"
    status = "Enabled"
    
    # Apply to all objects in the bucket
    filter {}

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete non-current versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket policy for secure access
resource "aws_s3_bucket_policy" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPresignedURLAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.tracecat.arn}/*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/AccessControlled" = "true"
          }
          StringLike = {
            "aws:UserAgent" = "Tracecat/*"
          }
          NumericLessThan = {
            "s3:signatureAge" = "30"
          }
        }
      },
      {
        Sid       = "AllowECSTaskAccess"
        Effect    = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.api_worker_task.arn,
            aws_iam_role.api_execution.arn,
            aws_iam_role.worker_execution.arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "${aws_s3_bucket.tracecat.arn}/*",
          aws_s3_bucket.tracecat.arn
        ]
      },
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tracecat.arn,
          "${aws_s3_bucket.tracecat.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# CORS configuration for case attachments
resource "aws_s3_bucket_cors_configuration" "tracecat" {
  bucket = aws_s3_bucket.tracecat.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${var.domain_name}"]
    expose_headers  = ["ETag", "Content-Type", "Content-Length", "Content-Disposition"]
    max_age_seconds = 3600
  }
}
