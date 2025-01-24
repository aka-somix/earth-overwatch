

#
# ------------------ TRAINING ------------------
#
# TODO: write training job code


#
# ------------------ INFERENCE ------------------
#

locals {
    yolo_folder = "landfill-yolo"
    yolo_version = "20250124"
}

# Build and upload model checkpoint
resource "null_resource" "build_yolo" {
  triggers = {
    version = local.yolo_version
  }
  
  provisioner "local-exec" {
    working_dir = "./yolo/inference"
    command = "./build.sh ${var.aws_s3_bucket_aimodels.bucket} ${local.yolo_version} ${local.yolo_folder}"
  }
}

# Create sagemaker resource based on model
resource "aws_sagemaker_model" "yolo" {
  name               = "${local.resprefix}-yolo-model"
  execution_role_arn = var.sagemaker_execution_role.arn

  primary_container {
    image          = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-inference:2.4-cpu-py311"
    mode           = "SingleModel"
    model_data_url = "s3://${var.aws_s3_bucket_aimodels.bucket}/models/${local.yolo_folder}/${local.yolo_version}/model.tar.gz"
  }

  depends_on = [ null_resource.build_yolo ]
}

# Expose model through endpoint

# Sagemaker Config
resource "aws_sagemaker_endpoint_configuration" "yolo" {
  name = "${local.resprefix}-yolo-config"
  production_variants {
    variant_name = "AllTraffic"
    model_name   = aws_sagemaker_model.yolo.name
    serverless_config {
      memory_size_in_mb = var.endpoint_memory
      max_concurrency   = var.endpoint_max_concurrency
    }
  }
}

# SageMaker Serverless Endpoint
resource "aws_sagemaker_endpoint" "yolo" {
  name                 = "${local.resprefix}-yolo-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.yolo.name

  lifecycle {
    replace_triggered_by = [aws_sagemaker_model.yolo]
  }
}
