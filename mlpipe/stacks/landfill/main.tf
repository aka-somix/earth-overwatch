locals {
  resprefix = "${var.project_name}-${var.env}"
}

#
# --- SAGE MAKER MODEL
#
resource "aws_sagemaker_model" "landfill_detection" {
  name          = "${local.resprefix}-detection-ai-model"
  execution_role_arn = aws_iam_role.landfill_sagemaker_execution_role.arn
  primary_container {
    image        = "" # TODO understand this part
    model_data_url = "" # TODO understand this part as well
  }
}

resource "aws_iam_role" "landfill_sagemaker_execution_role" {
  name = "${local.resprefix}-sagemaker-execrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "sagemaker.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "landfill_sagemaker_s3_access" {
  role   = aws_iam_role.landfill_sagemaker_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "${var.ai_models_bucket}/*"
      }
    ]
  })
}