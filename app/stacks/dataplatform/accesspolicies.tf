
resource "aws_iam_policy" "landingzonebucket_readonly" {
  name = "${local.resprefix}-landingzonebucket-readonly"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_policy" "landingzonebucket_writeread" {
  name = "${local.resprefix}-landingzonebucket-writeread"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ],
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "landingzonebucket_full" {
  name = "${local.resprefix}-landingzonebucket-full"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
    }
  )
}


resource "aws_iam_policy" "aimodelsbucket_readonly" {
  name = "${local.resprefix}-aimodelsbucket-readonly"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_policy" "aimodelsbucket_writeread" {
  name = "${local.resprefix}-aimodelsbucket-writeread"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ],
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "aimodelsbucket_full" {
  name = "${local.resprefix}-aimodelsbucket-full"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          "${module.landing_zone_bucket.arn}",
          "${module.landing_zone_bucket.arn}/*"
        ]
      }
    ]
    }
  )
}
