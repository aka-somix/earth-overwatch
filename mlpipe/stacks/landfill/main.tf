locals {
  resprefix = "${var.project_name}-${var.env}-landfill-"
}

resource "aws_sagemaker_model" "yologeneric" {
  name               = "${local.resprefix}-yolo-generic"
  execution_role_arn = var.sagemaker_execution_role.arn

  primary_container {
    image          = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-inference:2.4-cpu-py311"
    mode           = "SingleModel"
    model_data_url = "s3://${var.aws_s3_bucket_aimodels.bucket}/models/genericyolo/model-v20241102.tar.gz"
  }
}

# SageMaker Serverless Inference Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "yologeneric" {
  name = "${local.resprefix}-yolo11-generic-config"
  production_variants {
    variant_name = "AllTraffic"
    model_name   = aws_sagemaker_model.yologeneric.name
    serverless_config {
      memory_size_in_mb = 2048
      max_concurrency   = 5
    }
  }
}

# SageMaker Serverless Endpoint
resource "aws_sagemaker_endpoint" "yologeneric" {
  name                 = "${local.resprefix}-yolo11-generic"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.yologeneric.name
}
