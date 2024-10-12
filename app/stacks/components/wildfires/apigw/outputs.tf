# This is where you put your outputs declaration
output "api" {
  description = "The API Gateway REST API"
  value       = aws_api_gateway_rest_api.this
}
