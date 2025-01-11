# Main S3 Bucket Resource
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name           # Private access only
  force_destroy = var.destroyable
  tags          = var.bucket_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

# S3 Bucket Policy Resource
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowEventBridgeNotification",
        Effect    = "Allow",
        Principal = { Service = "s3.amazonaws.com" },
        Action    = ["s3:PutBucketNotification"],
        Resource  = "arn:aws:s3:::${aws_s3_bucket.this.bucket}",
      },
    ],
  })
}

# S3 Bucket Notification (EventBridge configuration)
resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id
  eventbridge = true
}

# S3 Bucket Lifecycle Configuration for transitioning objects to ONEZONE_IA after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id      = "TransitionToOneZoneIA"
    status  = "Enabled"

    transition {
      days          = 90
      storage_class = "ONEZONE_IA"
    }
  }
}
