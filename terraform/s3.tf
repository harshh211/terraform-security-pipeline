provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "s3_key" {
  description         = "KMS key for S3 bucket encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAccountAdmin"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

# --- Primary data bucket ---

resource "aws_s3_bucket" "data_bucket" {
  bucket = "harsh-devsecops-data-bucket"
}

resource "aws_s3_bucket_versioning" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_bucket" {
  bucket                  = aws_s3_bucket.data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "data_bucket" {
  bucket      = aws_s3_bucket.data_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket_logging" "data_bucket" {
  bucket        = aws_s3_bucket.data_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "data-bucket-log/"
}

# --- Log delivery bucket ---
# Receives access logs from data_bucket and replica_bucket. Held to the
# same bar as primary data (encryption, versioning, lifecycle,
# replication) since access logs are themselves sensitive audit data.

resource "aws_s3_bucket" "log_bucket" {
  bucket = "harsh-devsecops-log-bucket"
}

resource "aws_s3_bucket_versioning" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "log_bucket" {
  bucket      = aws_s3_bucket.log_bucket.id
  eventbridge = true
}

# --- Replication target bucket ---
# Shared destination for both data_bucket and log_bucket.

resource "aws_s3_bucket" "replica_bucket" {
  bucket = "harsh-devsecops-replica-bucket"
}

resource "aws_s3_bucket_versioning" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "replica_bucket" {
  bucket                  = aws_s3_bucket.replica_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica_bucket" {
  bucket = aws_s3_bucket.replica_bucket.id
  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_notification" "replica_bucket" {
  bucket      = aws_s3_bucket.replica_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket_logging" "replica_bucket" {
  bucket        = aws_s3_bucket.replica_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "replica-bucket-log/"
}

# --- Replication IAM role (shared by data_bucket and log_bucket) ---

resource "aws_iam_role" "s3_replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  name = "s3-replication-policy"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          aws_s3_bucket.log_bucket.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          "${aws_s3_bucket.data_bucket.arn}/*",
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.replica_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.replica_bucket.arn
    }
  }

  depends_on = [aws_s3_bucket_versioning.data_bucket]
}

resource "aws_s3_bucket_replication_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-logs"
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.replica_bucket.arn
    }
  }

  depends_on = [aws_s3_bucket_versioning.log_bucket]
}
