resource "aws_glue_job" "refine_oam" {
  name        = "${local.resprefix}-refine-oam"
  description = "Processing job for refining data from Open Aerial Map (oam)"

  role_arn = aws_iam_role.processing_glue_jobs.arn

  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  timeout           = 120 # 2 hours

  command {
    script_location = "s3://${aws_s3_object.glue_script_upload.bucket}/${aws_s3_object.glue_script_upload.key}"
    python_version  = 3
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.refine_oam.name
    "--enable-glue-datacatalog"          = "true"
    "--enable-glue-datacatalog"          = "true"
    # Apache Sedona
    "--additional-python-modules"        = "apache-sedona==1.7.0"
    "--extra-jars"                       = "https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.3_2.12/1.7.0/sedona-spark-shaded-3.3_2.12-1.7.0.jar,https://repo1.maven.org/maven2/org/datasyslab/geotools-wrapper/1.7.0-28.5/geotools-wrapper-1.7.0-28.5.jar"
    # Runtime parameters
    "--source_json_s3_path"              = "s3://${var.landing_zone_bucket.name}/oam/metadata/italy/2024/04/08/1738591402.json"
    "--destination_s3_path"              = "s3://${var.refined_zone_bucket.name}/oam/metadata/region=italy"
    "--destination_table"                = "aerial.oam"
  }

  execution_class = "FLEX"
  execution_property {
    max_concurrent_runs = 5
  }
}

# ------------ UPLOAD SCRIPT TO S3 ------------
resource "aws_s3_object" "glue_script_upload" {
  key    = "${var.project_name}/processing/oam_refine.py"
  bucket = var.aws_s3_bucket_glue_packages_name
  source = "${path.module}/glue-jobs/src/oam_refine.py"
  etag   = filemd5("${path.module}/glue-jobs/src/oam_refine.py")
}

# -------------- Cloudwatch Log Group --------------

resource "aws_cloudwatch_log_group" "refine_oam" {
  name              = "/${var.project_name}/glue/processing/refine-oam"
  retention_in_days = 7
}

#
# --- ORCHESTRATION ---
#

# SQS Queue for oam processing requests pending
resource "aws_sqs_queue" "oam_processing_requests" {
  name                      = "${local.resprefix}-oam-refining-requests-queue"
  fifo_queue                = false
  message_retention_seconds = 1209600  # 15 days
  visibility_timeout_seconds = 900  # 15 minutes
  max_message_size          = 262144  # 256 KB (default max)
  receive_wait_time_seconds = 10
}
resource "aws_sqs_queue_policy" "oam_processing_requests" {
  queue_url = aws_sqs_queue.oam_processing_requests.id
  policy    = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.oam_processing_requests.arn
      }
    ]
  })
}
resource "aws_sns_topic_subscription" "oam_processing_requests" {
  topic_arn = var.aws_sns_topic_oam_new_data_uploaded.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.oam_processing_requests.arn
}

resource "aws_sfn_state_machine" "oam_refine_orch" {
  name     = "${local.resprefix}-oam-refine-orch"
  role_arn = aws_iam_role.oam_refine_orch.arn

  definition = jsonencode({
    "StartAt": "RetrieveMessages",
    "States": {
      "RetrieveMessages": {
        "Type": "Task",
        "Resource": "arn:aws:states:::aws-sdk:sqs:receiveMessage",
        "Parameters": {
          "QueueUrl": "${aws_sqs_queue.oam_processing_requests.url}",
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
              "Next": "StartGlueJob"
            },
            "StartGlueJob": {
              "Type": "Task",
              "Resource": "arn:aws:states:::glue:startJobRun.sync",
              "Parameters": {
                "JobName": "${aws_glue_job.refine_oam.id}",
                "Arguments": {
                  "--source_json_s3_path.$": "$.Result.Message.meta_s3_uri"
                }
              },
              "ResultPath": null,
              "Next": "DeleteMessage"
            },
            "DeleteMessage": {
              "Resource": "arn:aws:states:::aws-sdk:sqs:deleteMessage",
              "Type": "Task",
              "Parameters": {
                "QueueUrl": "${aws_sqs_queue.oam_processing_requests.url}",
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


resource "aws_iam_role" "oam_refine_orch" {
  name = "${local.resprefix}-oam-refine-orch-role"

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
resource "aws_iam_role_policy" "oam_refine_orch_policy" {
  role = aws_iam_role.oam_refine_orch.name
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
        Resource = "${aws_sqs_queue.oam_processing_requests.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun"
        ],
        Resource = "${aws_glue_job.refine_oam.arn}"
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
