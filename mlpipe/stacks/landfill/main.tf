locals {
  resprefix = "${var.project_name}-${var.env}"
}

#
# --- SAGEMAKER TRAINING JOB ---
#
# resource "aws_sagemaker_training_job" "yolo_training_job" {
#   name     = "yolo-training-job"
#   role_arn = aws_iam_role.sagemaker_execution_role.arn
#   algorithm_specification {
#     training_image      = "763104351884.dkr.ecr.us-west-2.amazonaws.com/yolov5-training:latest" # Update with the actual YOLO image
#     training_input_mode = "File"
#   }

#   resource_config {
#     instance_type     = "ml.p3.2xlarge" # Change based on your training needs
#     instance_count    = 1
#     volume_size_in_gb = 50
#   }

#   stopping_condition {
#     max_runtime_in_seconds = 86400
#   }

#   input_data_config {
#     channel_name = "training"
#     data_source {
#       s3_data_source {
#         s3_data_type              = "S3Prefix"
#         s3_uri                    = "s3://${aws_s3_bucket.yolo_data_bucket.bucket}/training-data/"
#         s3_data_distribution_type = "FullyReplicated"
#       }
#     }
#   }

#   output_data_config {
#     s3_output_path = "s3://${aws_s3_bucket.yolo_data_bucket.bucket}/model-artifacts"
#   }

# }
