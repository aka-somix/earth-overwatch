resource "aws_lambda_function" "notebook_eraser" {
  function_name = "${local.resprefix}-notebook-eraser"
  runtime       = "python3.9"
  role          = aws_iam_role.notebook_eraser.arn
  handler       = "main.lambda_handler"
  filename      = data.archive_file.notebook_eraser.output_path

  source_code_hash = data.archive_file.notebook_eraser.output_sha256

  environment {
    variables = {
      # OS Variable for 
      TAG_KEY   = "project"
      TAG_VALUE = var.project_name
    }
  }
}

data "archive_file" "notebook_eraser" {
  type        = "zip"
  source_dir  = "${path.module}/services/notebook_eraser/"
  output_path = "${path.module}/services/notebook_eraser.zip"
}

resource "aws_iam_role" "notebook_eraser" {
  name               = "${local.resprefix}-notebook-eraser-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "access_sagemaker" {
  role = aws_iam_role.notebook_eraser.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ListAllow",
        "Effect" : "Allow",
        "Action" : [
          "sagemaker:List*",
          "sagemaker:GetResourcePolicy",
          "sagemaker:Search",
          "sagemaker:GetLineageGroupPolicy",
          "sagemaker:DescribeLineageGroup",
          "sagemaker:QueryLineage"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sagemaker:*"
        ],
        "Resource" : [
          "arn:aws:sagemaker:*:${var.account_id}:notebook-instance/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.notebook_eraser.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#
# --------------- SCHEDULER ---------------
# 
resource "aws_scheduler_schedule" "notebook_eraser" {
  name = "${local.resprefix}-notebook-eraser-schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 0 * * ? *)"

  target {
    arn      = aws_lambda_function.notebook_eraser.arn
    role_arn = aws_iam_role.notebook_eraser_scheduler.arn
  }
}

resource "aws_iam_role" "notebook_eraser_scheduler" {
  name = "${local.resprefix}-notebook-eraser-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "invoke_lambda" {
  role = aws_iam_role.notebook_eraser_scheduler.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "lambda:InvokeFunction",
        "Resource" : "${aws_lambda_function.notebook_eraser.arn}"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notebook_eraser.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_scheduler_schedule.notebook_eraser.arn
}
