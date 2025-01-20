# Create an ECR repository
resource "aws_ecr_repository" "tiling" {
  name         = "${local.resprefix}-tiling-repo"
  force_delete = true
}

locals {
  # tiling_imgtag = md5(join("", [for f in fileset("./tiling", "**/*") : md5(file(f))]))
  tiling_imgtag = md5(timestamp()) # TODO: change this to avoid to build the container everytime
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

  parameters = {
    MODE                  = "S3" # <-- Uses S3 for data transfer
    S3_BUCKET_SOURCE      = "placeholder-bucket-name"
    S3_BUCKET_DESTINATION = "placeholder-bucket-name"
    FILE_NAME             = "placeholder"
  }

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
        value = "800" # <-- This Should be edited as containerOverrde based on desired tiling
      },
      {
        name  = "MODE",
        value = "S3"
      },
      {
        name  = "S3_BUCKET_SOURCE",
        value = var.landing_zone_bucket.name
      },
      {
        name  = "S3_BUCKET_DESTINATION",
        value = var.refined_zone_bucket.name
      },
      {
        name  = "FILE_NAME",
        value = "placeholder"
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
    attempts = 3
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
