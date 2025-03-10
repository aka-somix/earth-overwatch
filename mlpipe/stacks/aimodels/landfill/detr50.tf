
locals {
  detr50_folder  = "landfill-detr50"
  detr50_version = "20250303.2"
}

#
# ------------------ INFERENCE ------------------
#

# Build and upload model checkpoint
resource "null_resource" "build_detr50" {
  triggers = {
    version = local.detr50_version
  }

  provisioner "local-exec" {
    working_dir = "./detr50/inference"
    command     = "./build.sh ${var.aws_s3_bucket_aimodels.bucket} ${local.detr50_version} ${local.detr50_folder}"
  }
}

# Create sagemaker resource based on model
resource "aws_sagemaker_model" "detr50" {
  name               = "${local.resprefix}-detr50-model"
  execution_role_arn = var.sagemaker_execution_role.arn

  primary_container {
    image          = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-inference:2.4-cpu-py311"
    mode           = "SingleModel"
    model_data_url = "s3://${var.aws_s3_bucket_aimodels.bucket}/models/${local.detr50_folder}/${local.detr50_version}/model.tar.gz"
  }

  depends_on = [null_resource.build_detr50]
}

# Expose model through endpoint

# Sagemaker Config
resource "aws_sagemaker_endpoint_configuration" "detr50" {
  name = "${local.resprefix}-detr50-config"
  production_variants {
    variant_name = "AllTraffic"
    model_name   = aws_sagemaker_model.detr50.name
    serverless_config {
      memory_size_in_mb = var.endpoint_memory
      max_concurrency   = var.endpoint_max_concurrency
    }
  }
}

# SageMaker Serverless Endpoint
resource "aws_sagemaker_endpoint" "detr50" {
  name                 = "${local.resprefix}-detr50-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.detr50.name

  lifecycle {
    replace_triggered_by = [aws_sagemaker_model.detr50]
  }
}
