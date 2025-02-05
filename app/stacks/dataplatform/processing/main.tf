locals {
  resprefix = "${var.project_name}-${var.env}-dp-proc"
}

#
# - MAIN COMPUTE ENVIRONMENT
#
resource "aws_batch_compute_environment" "main" {
  compute_environment_name = "${local.resprefix}-main"
  type                     = "MANAGED"
  state                    = "ENABLED"

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 1024
    min_vcpus          = 0
    subnets            = var.ce_subnets_ids
    security_group_ids = var.ce_security_groups_ids
  }
}

#
# - Data Processing Queues
#

# High Priority Queue
resource "aws_batch_job_queue" "data_processing_primary" {
  name     = "${local.resprefix}-dataprocessing-primary-queue"
  priority = 1
  state    = "ENABLED"

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.main.arn
  }
}


#
# --- GLUE JOBS ---
#

# ------------ IAM Role for Glue Jobs ------------
resource "aws_iam_role" "processing_glue_jobs" {
  name = "${local.resprefix}-glue-job-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "glue.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gluejob_read_landingzone" {
  role = aws_iam_role.processing_glue_jobs.name
  policy_arn = var.aws_policy_landingzonebucket_readonly.arn
}

resource "aws_iam_role_policy_attachment" "gluejob_writeread_refinedzone" {
  role = aws_iam_role.processing_glue_jobs.name
  policy_arn = var.aws_policy_redefinedzone_writeread.arn
}

resource "aws_iam_role_policy_attachment" "aws_glue_service_role" {
  role       = aws_iam_role.processing_glue_jobs.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_job_cloudwatch" {
  role = aws_iam_role.processing_glue_jobs.name
  name = "cloudwatch-custom-access"
  policy = jsonencode({
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:eu-west-1:772012299168:log-group:/${var.project_name}*"
            ]
        }
    ],
    "Version": "2012-10-17"
})
}