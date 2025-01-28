locals {
  resprefix = "${var.project_name}-${var.env}-sm"
}



#
# --- S3 BUCKETS ---
#
data "aws_s3_bucket" "aimodelsbucket" {
  bucket = data.aws_ssm_parameter.aimodelsbucket.insecure_value
}

#
# --- IAM ROLE ---
#
resource "aws_iam_role" "sagemaker_execution_role" {
  name = "${local.resprefix}-sagemaker-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "sagemaker.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_custom_access" {
  role = aws_iam_role.sagemaker_execution_role.name
  name = "s3-custom-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:*"],
        Resource = [
          "arn:aws:s3:::${data.aws_ssm_parameter.landingzonebucket.value}",
          "arn:aws:s3:::${data.aws_ssm_parameter.landingzonebucket.value}/*",
          "arn:aws:s3:::${data.aws_ssm_parameter.aimodelsbucket.value}",
          "arn:aws:s3:::${data.aws_ssm_parameter.aimodelsbucket.value}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecr_custom_access" {
  role = aws_iam_role.sagemaker_execution_role.name
  name = "ecr-custom-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:Describe*",
          "ecr:BatchGet*",
          "ecr:Get*",
          "ecr:List*"
        ],
        Resource = [
          "arn:aws:ecr:${var.region}:${var.account_id}:repository/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  role       = aws_iam_role.sagemaker_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "logs_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#
# --- NOTEBOOK FOR EXPERIMENTATION ---
#
resource "aws_sagemaker_notebook_instance" "experiments" {
  count    = var.include_notebook ? 1 : 0
  name     = "${local.resprefix}-experiments-nb"
  role_arn = aws_iam_role.sagemaker_execution_role.arn

  # Compute Settings
  instance_type = "ml.g4dn.xlarge" # https://aws.amazon.com/it/sagemaker/pricing/
  # Storage Settings
  volume_size = 10
  # Network Settings
  subnet_id = var.subnets[0]
  security_groups = var.security_group_ids
}
