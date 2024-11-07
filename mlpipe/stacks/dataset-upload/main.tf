locals {
  resprefix = "${var.project_name}-${var.env}-dataset-uploader"
}

# -------------- AWS Lambda Definition --------------
resource "aws_lambda_function" "dataset_uploader_service" {
  function_name    = "${local.resprefix}-service"
  role             = aws_iam_role.dataset_uploader_service.arn
  handler          = "main.handler"
  architectures    = ["arm64"]
  runtime          = "python3.12"
  source_code_hash = data.archive_file.dataset_uploader_service_lambda_package.output_base64sha256
  timeout          = 900 # 15min

  filename = data.archive_file.dataset_uploader_service_lambda_package.output_path

  vpc_config {
    subnet_ids = data.aws_subnets.rfalabs_dmz.ids
    security_group_ids = [
      data.aws_security_group.outbound_everywhere.id,
    ]
  }

  file_system_config {
    arn              = var.datasets_efs_access_point.arn
    local_mount_path = "/mnt/datasets"
  }

  depends_on = [
    aws_cloudwatch_log_group.dataset_uploader_service
  ]
}

# -------------- Build and Upload --------------

data "archive_file" "dataset_uploader_service_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = "${path.module}/lambda/build/out.zip"
}

# -------------- IAM Configuration --------------
resource "aws_iam_role" "dataset_uploader_service" {
  name = "${local.resprefix}-role"
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

resource "aws_iam_role_policy" "access_s3" {
  role = aws_iam_role.dataset_uploader_service.id
  name = "access-every-bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "arn:aws:s3:::*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : "arn:aws:s3:::*/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execute_role_dataset_uploader_service" {
  role       = aws_iam_role.dataset_uploader_service.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Access
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.dataset_uploader_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -------------- Cloudwatch Log Group --------------
locals {
  log_group_name_dataset_uploader_service = "/aws/lambda/${local.resprefix}-service"
}

resource "aws_cloudwatch_log_group" "dataset_uploader_service" {
  name              = local.log_group_name_dataset_uploader_service
  retention_in_days = 1
}
