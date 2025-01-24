locals {
  resprefix = "${var.project_name}-${var.env}-yologeneric"
  folder = "yologeneric"
  version = "20250124"
}

#
# --------- INFERENCE ---------
#

# Build and upload model checkpoint
resource "null_resource" "build_model" {
  triggers = {
    version = local.version
  }
  
  provisioner "local-exec" {
    working_dir = "./inference"
    command = "./build.sh ${var.aws_s3_bucket_aimodels.bucket} ${local.version} ${local.folder}"
  }
}

# Create sagemaker resource based on model
resource "aws_sagemaker_model" "this" {
  name               = "${local.resprefix}-model"
  execution_role_arn = var.sagemaker_execution_role.arn

  primary_container {
    image          = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-inference:2.4-cpu-py311"
    mode           = "SingleModel"
    model_data_url = "s3://${var.aws_s3_bucket_aimodels.bucket}/models/${local.folder}/${local.version}/model.tar.gz"
  }
}

# Expose model through endpoint

# Sagemaker Config
resource "aws_sagemaker_endpoint_configuration" "this" {
  name = "${local.resprefix}-config"
  production_variants {
    variant_name = "AllTraffic"
    model_name   = aws_sagemaker_model.this.name
    serverless_config {
      memory_size_in_mb = var.endpoint_memory
      max_concurrency   = var.endpoint_max_concurrency
    }
  }
}

# SageMaker Serverless Endpoint
resource "aws_sagemaker_endpoint" "this" {
  name                 = "${local.resprefix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.this.name

  lifecycle {
    replace_triggered_by = [aws_sagemaker_model.this]
  }
}
