#
# --- SERVICES DEFINITION ---
#
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
  "StartAt": "Parse Input Event",
  "States": {
    "Parse Input Event": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:eu-west-1:772012299168:function:ParseInputEvent",
        "Payload.$": "$"
      },
      "Next": "Fetch Bucket Map",
      "ResultPath": "$.Parsed"
    },
    "Fetch Bucket Map": {
      "Type": "Map",
      "Label": "FetchBucketMap",
      "MaxConcurrency": 100,
      "ItemReader": {
        "Resource": "arn:aws:states:::s3:listObjectsV2",
        "Parameters": {
          "Bucket.$": "$.Parsed.Bucket",
          "Prefix.$": "$.Parsed.Prefix"
        }
      },
      "ItemBatcher": {
        "MaxItemsPerBatch": 10,
        "MaxInputBytesPerBatch": 262144
      },
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "DISTRIBUTED",
          "ExecutionType": "STANDARD"
        },
        "StartAt": "S3 Object Batch Processing",
        "States": {
          "S3 Object Batch Processing": {
            "ItemProcessor": {
              "ProcessorConfig": {
                "Mode": "INLINE"
              },
              "StartAt": "Parse Object into SQS Message",
              "States": {
                "Parse Object into SQS Message": {
                  "End": true,
                  "Parameters": {
                    "Id.$": "States.Hash($.Etag, 'MD5')",
                    "MessageBody.$": "$.Key"
                  },
                  "Type": "Pass"
                }
              }
            },
            "ItemsPath": "$.Items",
            "Type": "Map",
            "Next": "SendMessageBatch"
          },
          "SendMessageBatch": {
            "End": true,
            "Parameters": {
              "Entries.$": "$",
              "QueueUrl": "https://sqs.eu-west-1.amazonaws.com/772012299168/scrnts-dev-landfill-images-to-predict"
            },
            "Resource": "arn:aws:states:::aws-sdk:sqs:sendMessageBatch",
            "Type": "Task"
          }
        }
      },
      "End": true
    }
  }
}
)
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
        Effect = "Allow",
        Action = [
          "s3:*",
          "sqs:*",
          "states:*"
        ],
        Resource = "*"
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
