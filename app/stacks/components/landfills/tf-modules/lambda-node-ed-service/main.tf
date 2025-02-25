resource "aws_lambda_function" "this" {
  function_name = var.function_name

  s3_bucket        = aws_s3_object.lambda_zip_build.bucket
  s3_key           = aws_s3_object.lambda_zip_build.key
  source_code_hash = data.archive_file.source.output_md5

  runtime       = "nodejs20.x"
  memory_size   = var.memory_size
  architectures = var.architectures
  handler       = var.handler
  timeout       = var.timeout

  role = aws_iam_role.this.arn

  dynamic "vpc_config" {
    for_each = var.vpc.enabled ? [1] : []
    content {
      subnet_ids         = var.vpc.subnet_ids
      security_group_ids = var.vpc.security_group_ids
    }
  }

  environment {
    variables = var.env_vars
  }

  depends_on = [aws_s3_object.lambda_zip_build]
}

#
# IAM Role for Lambda function
#
resource "aws_iam_role" "this" {
  name = "${var.function_name}-lambdarole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

# Lambda Basics Policy (Cloudwatch logs)
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Access
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#
# Lambda Build and Upload to S3
#
resource "null_resource" "build_package" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    working_dir = var.source_code_folder
    command     = "pnpm install"
  }

  provisioner "local-exec" {
    working_dir = var.source_code_folder
    command     = "pnpm build"
  }
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${var.source_code_folder}/dist"
  output_path = "${var.source_code_folder}/${var.function_name}.zip"

  depends_on = [null_resource.build_package]
}

resource "aws_s3_object" "lambda_zip_build" {
  bucket = var.lambda_packages_bucket
  key    = "${var.function_name}.zip"
  source = data.archive_file.source.output_path
  etag   = data.archive_file.source.output_md5

  depends_on = [data.archive_file.source]
}

# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.logs_retention_days
}

# -------------- RESOURCE POLICY --------------
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"

  # Replace with your custom event bus ARN
  source_arn = var.eventbridge_bus_arn
}
