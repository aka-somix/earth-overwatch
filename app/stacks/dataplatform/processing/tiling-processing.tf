# Create an ECR repository
resource "aws_ecr_repository" "tiling" {
  name         = "${local.resprefix}-tiling-repo"
  force_delete = true
}

locals {
  tiling_imgtag = md5(join("", sort([for f in fileset("./tiling", "**/*") : md5(filebase64("${path.module}/tiling/${f}"))])))
}

resource "null_resource" "build_and_upload_image" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    imgtag = "${local.tiling_imgtag}"
  }

  provisioner "local-exec" {
    working_dir = "./tiling"
    command     = "./build.sh -r ${var.region} -e ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com -n ${aws_ecr_repository.tiling.name} -t ${local.tiling_imgtag}"
  }
}


# Create an AWS Batch Job Definition
resource "aws_batch_job_definition" "tiling_job" {
  name = "${local.resprefix}-tiling-jobdef"

  type = "container"

  platform_capabilities = [
    "FARGATE",
  ]
  container_properties = jsonencode({
    image            = "${aws_ecr_repository.tiling.repository_url}:${local.tiling_imgtag}",
    command          = ["python", "main.py"],
    jobRoleArn       = aws_iam_role.batch_job_role.arn,
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "1"
      },
      {
        type  = "MEMORY"
        value = "2048"
      }
    ]
    environment = [
      {
        name  = "TILE_SIZE",
        value = "800"                         # <-- This Should be edited as containerOverrde based on desired tiling
      },
      {
        name  = "MODE",
        value = "S3"
      },
      {
        name  = "S3_SOURCE_URL",
        value = "s3://placeholder/file.tif"   # <-- This Should be edited as containerOverrde based on desired tiling
      },
      {
        name  = "S3_DEST_BUCKET",
        value = var.refined_zone_bucket.name
      },
      {
        name  = "S3_DEST_PREFIX",
        value = "examples/tiles/800/"         # <-- This Should be edited as containerOverrde based on desired tiling
      },
      {
        name  = "FILE_NAME",
        value = "placeholder"                 # <-- This Should be edited as containerOverrde based on desired tiling
      },
      {
        name  = "LOCAL_DIR",
        value = "/tmp/"
      },
    ],
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.tiling.name
      }
    }
  })

  timeout {
    attempt_duration_seconds = 1800 # 1 hour
  }

  retry_strategy {
    attempts = 1
  }
}

# Create an IAM role for the ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.resprefix}-tiling-taskexec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# Attach the AmazonECSTaskExecutionRolePolicy to the ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create a job execution role for AWS Batch
resource "aws_iam_role" "batch_job_role" {
  name = "${local.resprefix}-tiling-job"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "batch_job_policy_attachment" {
  role = aws_iam_role.batch_job_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:DescribeRepositories", "ecr:BatchGetImage"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "logs:CreateLogStream",
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.tiling.arn}:*"
      },
      {
        Action   = "logs:PutLogEvents",
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.tiling.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "landingzone" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = var.aws_policy_landingzonebucket_readonly.arn
}

resource "aws_iam_role_policy_attachment" "refinedzone" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = var.aws_policy_redefinedzone_writeread.arn
}


# Create a custom CloudWatch Log Group for AWS Batch
resource "aws_cloudwatch_log_group" "tiling" {
  name              = "/aws/batch/tiling"
  retention_in_days = 1
}


#
# --- ORCHESTRATION ---
#

# SQS Queue for tiling requests pending
resource "aws_sqs_queue" "tiling_requests_queue" {
  name                      = "${local.resprefix}-tiling-requests-queue"
  fifo_queue                = false
  message_retention_seconds = 1209600  # 15 days
  visibility_timeout_seconds = 900  # 15 minutes
  max_message_size          = 262144  # 256 KB (default max)
  receive_wait_time_seconds = 10
}
resource "aws_sqs_queue_policy" "tiling_requests_queue" {
  queue_url = aws_sqs_queue.tiling_requests_queue.id
  policy    = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.tiling_requests_queue.arn
      }
    ]
  })
}
resource "aws_sns_topic_subscription" "tiling_requests_subscription_to_oam" {
  topic_arn = var.aws_sns_topic_oam_new_data_uploaded.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.tiling_requests_queue.arn
}

resource "aws_sfn_state_machine" "tiling_orchestration" {
  name     = "${local.resprefix}-tiling-rch"
  role_arn = aws_iam_role.tiling_orchestration.arn

  definition = jsonencode({
    "StartAt": "RetrieveMessages",
    "States": {
      "RetrieveMessages": {
        "Type": "Task",
        "Resource": "arn:aws:states:::aws-sdk:sqs:receiveMessage",
        "Parameters": {
          "QueueUrl": "${aws_sqs_queue.tiling_requests_queue.url}",
          "MaxNumberOfMessages": 10,
          "WaitTimeSeconds": 10
        },
        "ResultPath": "$",
        "Next": "CheckMessages"
      },
      "CheckMessages": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.Messages",
            "IsPresent": true,
            "Next": "ProcessMessages"
          }
        ],
        "Default": "EndState"
      },
      "ProcessMessages": {
        "Type": "Map",
        "InputPath": "$.Messages",
        "ItemsPath": "$",
        "MaxConcurrency": 5,
        "Iterator": {
          "StartAt": "ExtractBody",
          "States": {
            "ExtractBody": {
              "Next": "ExtractMessage",
              "Parameters": {
                "Body.$": "States.StringToJson($.Body)",
                "ReceiptHandle.$": "$.ReceiptHandle"
              },
              "Type": "Pass"
            },
            "ExtractMessage": {
              "Parameters": {
                "Message.$": "States.StringToJson($.Body.Message)",
                "ReceiptHandle.$": "$.ReceiptHandle"
              },
              "Type": "Pass",
              "ResultPath": "$.Result",
              "Next": "SubmitBatchJob"
            },
            "SubmitBatchJob": {
              "Type": "Task",
              "Resource": "arn:aws:states:::batch:submitJob.sync",
              "Parameters": {
                "JobName": "${aws_batch_job_definition.tiling_job.name}",
                "JobQueue": "${aws_batch_job_queue.data_processing_primary.id}",
                "JobDefinition": "${aws_batch_job_definition.tiling_job.arn}",
                "ContainerOverrides": {
                  "Environment": [
                    {
                      "Name": "S3_SOURCE_URL",
                      "Value.$": "$.Result.Message.img_s3_uri"
                    },
                    {
                      "Name": "S3_DEST_PREFIX",
                      "Value": "oam/tiles/800"
                    }
                  ]
                }
              },
              "ResultPath": "$.batch",
              "Next": "DeleteMessage"
            },
            "DeleteMessage": {
              "Resource": "arn:aws:states:::aws-sdk:sqs:deleteMessage",
              "Type": "Task",
              "Parameters": {
                "QueueUrl": "${aws_sqs_queue.tiling_requests_queue.url}",
                "ReceiptHandle.$": "$.Result.ReceiptHandle"
              },
              "End": true
            }
          }
        },
        "End": true
      },
      "EndState": {
        "Type": "Succeed"
      }
    }
  })
}


resource "aws_iam_role" "tiling_orchestration" {
  name = "${local.resprefix}-tiling-orch-role"

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

resource "aws_iam_role_policy" "tiling_orchestration_policy" {
  role = aws_iam_role.tiling_orchestration.name
  name = "orchestration-main-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = "${aws_sqs_queue.tiling_requests_queue.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "batch:SubmitJob",
          "batch:DescribeJobs"
        ],
        Resource = [
          "${aws_batch_job_definition.tiling_job.arn}",
          "${aws_batch_job_queue.data_processing_primary.arn}"
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
