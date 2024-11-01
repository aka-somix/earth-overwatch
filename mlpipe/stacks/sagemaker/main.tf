locals {
  resprefix = "${var.project_name}-${var.env}-sm"
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

resource "aws_iam_role_policy" "sagemaker_s3_access" {
  role = aws_iam_role.sagemaker_execution_role.name
  name = "s3-access"

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

#
# --- NOTEBOOK FOR EXPERIMENTATION ---
#
resource "aws_sagemaker_notebook_instance" "experiments" {
  name     = "${local.resprefix}-experiments-nb"
  role_arn = aws_iam_role.sagemaker_execution_role.arn

  # Compute Settings
  instance_type = "ml.t2.medium"
  # Storage Settings
  volume_size = 10
  # Network Settings
  subnet_id = data.aws_subnets.rfalabs_dmz.ids[0]
  security_groups = [
    data.aws_security_group.outbound_everywhere.id
  ]
}
