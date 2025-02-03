resource "aws_lambda_function" "download_meta" {
  function_name     = "${local.resprefix}-download-meta"
  role              = aws_iam_role.download_meta.arn
  filename          = data.archive_file.source.output_path
  source_code_hash  = data.archive_file.source.output_sha256

  handler = "main.lambda_handler"
  memory_size = 128
  timeout = 30
  runtime = "python3.12"

  environment {
    variables = {
      OAM_ENDPOINT="http://api.openaerialmap.org/meta"
      LANDINGZONE_BUCKET=var.landing_zone_bucket.name
    }
  }

  depends_on = [ null_resource.build ]
}

resource "aws_iam_role" "download_meta" {
  name = "${local.resprefix}-download-meta"

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
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.download_meta.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "access_landing_zone_bucket" {
  role       = aws_iam_role.download_meta.name
  policy_arn = var.aws_policy_landingzonebucket_writeread.arn
}


# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "download_meta" {
  name              = "/aws/lambda/${local.resprefix}-download-meta"
  retention_in_days = 7
}


#
# -------------- Lambda container build and upload --------------
#

resource "null_resource" "build" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    timestamp() = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/download-meta"
    command     = "chmod +x build.sh && ./build.sh"
  }
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/download-meta/src"
  output_path = "${path.module}/download-meta/bin/out.zip"

  depends_on = [null_resource.build]
}