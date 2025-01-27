
locals {
    yolo_folder = "landfill-yolo"
    yolo_version = "20250124"
}

#
# ------------------ TRAINING ------------------
#
# Training container Repository
resource "aws_ecr_repository" "yolo_train" {
  name = "${local.resprefix}-train-repo"

  image_tag_mutability = "MUTABLE"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "yolo_train" {
  repository = aws_ecr_repository.yolo_train.id
  policy = jsonencode({
  "rules": [
    {
      "rulePriority": 1,
      "description": "Retain only the latest 3 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    }
  ]
})
}

# Build and upload training container
resource "null_resource" "build_and_upload_yolo_train" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    imgtag = "${local.yolo_version}"
  }

  provisioner "local-exec" {
    working_dir = "./tiling"
    command     = <<EOF
                  ./build.sh \
                    -r ${var.region} 
                    -e ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com 
                    -n ${aws_ecr_repository.yolo_train.name} 
                    -t ${local.yolo_version}
                    -v ${local.yolo_version}
                    -y "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11m.pt"
                    -d "" # TODO Add dataset path
EOF
  }
}

resource "aws_iam_role" "step_functions_role" {
  name = "${local.resprefix}-training-orch-role"

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

# Training Jobs orchestration
resource "aws_iam_role_policy" "step_functions_policy" {
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "sagemaker_training_job" {
  name     = "${local.resprefix}-training-orch"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = templatefile("${path.module}/state_machine_definition.json", {
    training_image        = "${aws_ecr_repository.yolo_train.repository_url}"
    sagemaker_role_arn    = "arn:aws:iam::123456789012:role/service-role/SageMakerExecutionRole" # TODO: Replace with your SageMaker role ARN
    efs_filesystem_id     = "fs-12345678"                     # TODO Replace with your EFS file system ID
    efs_mount_path        = "/mnt/efs"                        # TODO Replace with your EFS mount path
    s3_output_folder_uri  = "s3://your-bucket-name/output/"   # TODO: Replace
    training_instance_type = "ml.p3.2xlarge"
  })
}

#
# ------------------ INFERENCE ------------------
#

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
