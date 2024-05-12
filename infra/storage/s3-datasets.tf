# 
# S3 Bucket for storing Glue Job Custom Scripts and libraries to
#  
resource "aws_s3_bucket" "training_datasets" {
  bucket = "${var.prefix}-datasets-${var.account_id}-${var.region}"
}

resource "aws_s3_bucket_ownership_controls" "training_datasets" {
  bucket = aws_s3_bucket.training_datasets.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "training_datasets" {
  bucket = aws_s3_bucket.training_datasets.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.training_datasets]
}

# Bucket Policy Resource
resource "aws_s3_bucket_policy" "training_datasets_s3_secure_transport" {
  bucket = aws_s3_bucket.training_datasets.id
  policy = data.aws_iam_policy_document.training_datasets_bucket_policy.json
}

# Bucket Policy definition
data "aws_iam_policy_document" "training_datasets_bucket_policy" {
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "${aws_s3_bucket.training_datasets.arn}",
      "${aws_s3_bucket.training_datasets.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}
