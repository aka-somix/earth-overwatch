resource "aws_sfn_state_machine" "oam_orchestration" {
  name     = "${local.resprefix}-orchestration"
  role_arn = aws_iam_role.oam_orchestration.arn

  definition = jsonencode({
    "Comment": "Orchestrates two Lambda functions with parallel execution and SNS notification",
    "StartAt": "Ingest Metadata",
    "States": {
        "Ingest Metadata": {
          "Type": "Task",
          "Resource": "${aws_lambda_function.download_meta.arn}",
          "ResultPath": "$",
          "Next": "Ingest Images"
        },
        "Ingest Images": {
          "Type": "Map",
          "MaxConcurrency": 7,
          "InputPath": "$.meta",
          "ItemProcessor": {
              "ProcessorConfig": {
                "Mode": "INLINE"
              },
              "StartAt": "Process Image",
              "States": {
                "Process Image": {
                    "Type": "Task",
                    "Resource": "${aws_lambda_function.download_image.arn}",
                    "Parameters": {
                      "meta": {
                        "id.$": "$.id",
                        "img_url.$": "$.img_url",
                        "date.$": "$.date"
                      }
                    },
                    "ResultPath": "$.processed_image",
                    "Next": "Send SNS Notification"
                },
                "Send SNS Notification": {
                  "Type": "Task",
                  "Resource": "arn:aws:states:::sns:publish",
                  "Parameters": {
                    "TopicArn": "${aws_sns_topic.new_data_uploaded.arn}",
                    "Message": {
                      "id.$": "$.processed_image.id",
                      "img_s3_uri.$": "$.processed_image.img_s3_uri",
                      "meta_s3_uri.$": "$.meta_s3_uri"
                    },
                    "Subject": "Image Processing Completed"
                  },
                  "End": true
                }
              }
          },
          "ResultPath": "$.processed_images",
          "Next": "SuccessState"
        },
        "SuccessState": {
          "Type": "Succeed"
        }
    }
  })
}


resource "aws_iam_role" "oam_orchestration" {
  name = "${local.resprefix}-orchestration-role"

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

resource "aws_iam_role_policy" "oam_orchestration_policy" {
  role    = aws_iam_role.oam_orchestration.name 
  name    = "${local.resprefix}-orchestration-policy"
  policy  = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [
          aws_lambda_function.download_meta.arn,
          aws_lambda_function.download_image.arn
        ]
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
          "sns:Publish"
        ],
        Resource = aws_sns_topic.new_data_uploaded.arn
      }
    ]
  })
}
