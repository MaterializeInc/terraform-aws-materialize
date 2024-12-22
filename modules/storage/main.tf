locals {
  name_prefix = "${var.namespace}-${var.environment}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "materialize_storage" {
  bucket        = "${local.name_prefix}-storage-${random_id.bucket_suffix.hex}"
  force_destroy = var.bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "materialize_storage" {
  count = var.enable_bucket_versioning ? 1 : 0 # Only create if versioning is enabled

  bucket = aws_s3_bucket.materialize_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "materialize_storage" {
  count = var.enable_bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.materialize_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "materialize_storage" {
  count = length(var.bucket_lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.materialize_storage.id

  dynamic "rule" {
    for_each = var.bucket_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      transition {
        days          = rule.value.transition_days
        storage_class = rule.value.transition_storage_class
      }

      expiration {
        days = rule.value.expiration_days
      }

      noncurrent_version_expiration {
        noncurrent_days = rule.value.noncurrent_version_expiration_days
      }
    }
  }
}
