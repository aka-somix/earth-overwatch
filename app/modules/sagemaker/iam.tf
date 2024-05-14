
resource "aws_iam_role" "sagemaker_domain" {
  name               = var.domain_role_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "sagemaker_forecast" {
  name               = var.forecast_role_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json

  tags = var.tags
}

data "aws_iam_policy" "AmazonSageMakerCanvasFullAccess" {
  name = "AmazonSageMakerCanvasFullAccess"
}

data "aws_iam_policy" "AmazonSageMakerFullAccess" {
  name = "AmazonSageMakerFullAccess"
}

data "aws_iam_policy" "AmazonSageMakerCanvasForecastAccess" {
  name = "AmazonSageMakerCanvasForecastAccess"
}

data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sagemaker_forecast_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["forecast.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sagemaker_s3_data" {
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [var.sharing_settings_bucket.arn]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    effect    = "Allow"
    resources = [var.sharing_settings_bucket.arn]
  }
}

resource "aws_iam_policy" "sagemaker_s3_data" {
  name   = "sagemaker_s3_data"
  policy = data.aws_iam_policy_document.sagemaker_s3_data.json
}

resource "aws_iam_role_policy_attachment" "AmazonSageMakerCanvasFullAccess" {
  policy_arn = data.aws_iam_policy.AmazonSageMakerCanvasFullAccess.arn
  role       = aws_iam_role.sagemaker_domain.id
}

resource "aws_iam_role_policy_attachment" "AmazonSageMakerCanvasForecastAccess" {
  policy_arn = data.aws_iam_policy.AmazonSageMakerCanvasForecastAccess.arn
  role       = aws_iam_role.sagemaker_domain.id
}

resource "aws_iam_role_policy_attachment" "AmazonSageMakerFullAccess" {
  policy_arn = data.aws_iam_policy.AmazonSageMakerFullAccess.arn
  role       = aws_iam_role.sagemaker_domain.id
}

resource "aws_iam_role_policy_attachment" "sagemaker_s3_data" {
  policy_arn = aws_iam_policy.sagemaker_s3_data.arn
  role       = aws_iam_role.sagemaker_domain.id
}
