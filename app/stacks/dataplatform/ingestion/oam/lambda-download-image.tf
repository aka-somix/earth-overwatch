resource "aws_lambda_function" "download_image" {
  function_name    = "${local.resprefix}-download-image"
  role             = aws_iam_role.download_image.arn
  filename         = data.archive_file.download_image_source.output_path
  source_code_hash = data.archive_file.download_image_source.output_sha256

  handler     = "main.lambda_handler"
  memory_size = 512
  timeout     = 900
  runtime     = "python3.12"

  environment {
    variables = {
      LANDINGZONE_BUCKET = var.landing_zone_bucket.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.download_image]
}

resource "aws_iam_role" "download_image" {
  name = "${local.resprefix}-download-image"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


# Lambda Basics Policy (Cloudwatch logs)
resource "aws_iam_role_policy_attachment" "download_image_basic_execution" {
  role       = aws_iam_role.download_image.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "download_image_access_landing_zone_bucket" {
  role       = aws_iam_role.download_image.name
  policy_arn = var.aws_policy_landingzonebucket_writeread.arn
}


# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "download_image" {
  name              = "/aws/lambda/${local.resprefix}-download-image"
  retention_in_days = 7
}


#
# -------------- Lambda container build and upload --------------
#

resource "null_resource" "download_image_build" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    timestamp() = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/download-image"
    command     = "chmod +x build.sh && ./build.sh"
  }
}

data "archive_file" "download_image_source" {
  type        = "zip"
  source_dir  = "${path.module}/download-image/src"
  output_path = "${path.module}/download-image/bin/out.zip"

  depends_on = [null_resource.download_image_build]
}
