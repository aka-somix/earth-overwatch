# This is where you put your outputs declaration

output "iam_role" {
  value = aws_iam_role.this
}

output "arn" {
  value = aws_lambda_function.this.arn
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}
