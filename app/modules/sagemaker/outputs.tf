# This is where you put your outputs declaration

output "sagemaker_domain" {
  value = aws_sagemaker_domain.this
}

output "sagemaker_user" {
  value = aws_sagemaker_user_profile.this
}
