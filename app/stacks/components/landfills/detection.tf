#
# --- SERVICES DEFINITION ---
#

# Parse Detection Input Service
resource "aws_lambda_function" "parse_detection_input" {
  function_name     = "${local.resprefix}-parse-detection-input"
  role              = aws_iam_role.parse_detection_input.arn
  filename          = data.archive_file.parse_detection_input_source.output_path
  source_code_hash  = data.archive_file.parse_detection_input_source.output_sha256

  handler = "main.lambda_handler"
  memory_size = 128
  timeout = 300
  runtime = "python3.12"

  depends_on = [ aws_cloudwatch_log_group.parse_detection_input]
}


data "archive_file" "parse_detection_input_source" {
  type        = "zip"
  source_dir  = "${path.module}/detection/parse-detecton-input/src"
  output_path = "${path.module}/detection/parse-detecton-input/bin/out.zip"
}

resource "aws_iam_role" "parse_detection_input" {
  name = "${local.resprefix}-parse-detection-input"

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
resource "aws_iam_role_policy_attachment" "parse_detection_input_basic_execution" {
  role       = aws_iam_role.parse_detection_input.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "parse_detection_input_main_policy" {
  role = aws_iam_role.parse_detection_input.name
  name = "lambda-main-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
  })
}

# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "parse_detection_input" {
  name              = "/aws/lambda/${local.resprefix}-parse-detection-input"
  retention_in_days = 7
}


# Run Detection Service
resource "aws_lambda_function" "run_detection" {
  function_name     = "${local.resprefix}-run-detection"
  role              = aws_iam_role.run_detection.arn
  filename          = data.archive_file.run_detection_source.output_path
  source_code_hash  = data.archive_file.run_detection_source.output_sha256

  handler = "main.lambda_handler"
  memory_size = 128
  timeout = 300
  runtime = "python3.12"

  environment {
    variables = {
      API_KEY                 = data.aws_api_gateway_api_key.personal.value
      DETECTION_QUEUE_URL     = aws_sqs_queue.images_to_predict.url
      GEO_API_BASE_URL        = var.geo_apigw_endpoint
      LANDFILL_API_BASE_URL   = aws_api_gateway_stage.env.invoke_url
      SAGEMAKER_ENDPOINT      = "TODO"
      TILES_PER_RUN           = 1
    }
  }

  depends_on = [ aws_cloudwatch_log_group.run_detection]
}

resource "null_resource" "run_detection_build" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    timestamp() = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/detection/run-detection"
    command     = "chmod +x build.sh && ./build.sh"
  }
}

data "archive_file" "run_detection_source" {
  type        = "zip"
  source_dir  = "${path.module}/detection/run-detection/src"
  output_path = "${path.module}/detection/run-detection/bin/out.zip"
  excludes    = [".terragrunt*"]
  depends_on  = [null_resource.run_detection_build]
}

resource "aws_iam_role" "run_detection" {
  name = "${local.resprefix}-run-detection"

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
resource "aws_iam_role_policy_attachment" "run_detection_basic_execution" {
  role       = aws_iam_role.run_detection.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "run_detection_main_policy" {
  role = aws_iam_role.run_detection.name
  name = "lambda-main-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:DeleteMessageBatch",
                "sqs:GetQueueAttributes"
            ],
            "Resource": "${aws_sqs_queue.images_to_predict.arn}"
        }
    ]
  })
}

# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "run_detection" {
  name              = "/aws/lambda/${local.resprefix}-run-detection"
  retention_in_days = 7
}


#
# --- ORCHESTRATION ---
#

# SQS Queue for tiling requests pending
resource "aws_sqs_queue" "images_to_predict" {
  name                      = "${local.resprefix}-images-to-predict"
  fifo_queue                = false
  message_retention_seconds = 1209600  # 15 days
  visibility_timeout_seconds = 300  # 15 minutes
  max_message_size          = 262144  # 256 KB (default max)
}


resource "aws_sfn_state_machine" "detection_orchestration" {
  name     = "${local.resprefix}-detection-orch"
  role_arn = aws_iam_role.detection_orchestration.arn

  definition = jsonencode({
    "StartAt": "Parse Tiles from Input",
    "States": {
      "Parse Tiles from Input": {
        "Parameters": {
          "FunctionName": "${aws_lambda_function.parse_detection_input.arn}",
          "Payload.$": "$"
        },
        "Resource": "arn:aws:states:::lambda:invoke",
        "Type": "Task",
        "OutputPath": "$.Payload",
        "Next": "Batch and distribute Tiles"
      },
      "Batch and distribute Tiles": {
        "Type": "Map",
        "ItemProcessor": {
          "ProcessorConfig": {
            "Mode": "DISTRIBUTED",
            "ExecutionType": "STANDARD"
          },
          "StartAt": "Send Detection Request on Tiles Batch",
          "States": {
            "Send Detection Request on Tiles Batch": {
              "Type": "Task",
              "Parameters": {
                "Entries.$": "$.Items",
                "QueueUrl": "${aws_sqs_queue.images_to_predict.url}"
              },
              "Resource": "arn:aws:states:::aws-sdk:sqs:sendMessageBatch",
              "End": true
            }
          }
        },
        "End": true,
        "Label": "BatchanddistributeTiles",
        "MaxConcurrency": 1000,
        "ItemBatcher": {
          "MaxItemsPerBatch": 10,
          "MaxInputBytesPerBatch": 262144
        },
        "ItemsPath": "$.Entries"
      }
    }
  })
}


resource "aws_iam_role" "detection_orchestration" {
  name = "${local.resprefix}-detection-orch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "detection_orchestration_policy" {
  role = aws_iam_role.detection_orchestration.name
  name = "orchestration-main-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:SendMessage",
          "sqs:SendMessageBatch",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        "Resource": "${aws_sqs_queue.images_to_predict.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "states:StartExecution",
          "states:DescribeExecution",
          "states:StopExecution"
        ],
        "Resource": "arn:aws:states:${var.region}:${var.account_id}:stateMachine:${local.resprefix}-*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "lambda:InvokeFunction"
        ],
        "Resource": "${aws_lambda_function.parse_detection_input.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ],
        Resource = [
          "arn:aws:events:${var.region}:${var.account_id}:rule/*"
        ]
      }
    ]
  })
}
