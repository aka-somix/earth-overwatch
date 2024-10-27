# This is where you put your outputs declaration
output "name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}
