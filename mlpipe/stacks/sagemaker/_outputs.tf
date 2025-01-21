# This is where you put your outputs declaration

output "sagemaker_execution_role" {
  value = aws_iam_role.sagemaker_execution_role
}

output "aws_s3_bucket_aimodels" {
  value = data.aws_s3_bucket.aimodelsbucket
}
