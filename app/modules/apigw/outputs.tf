# This is where you put your outputs declaration
output "api_gateway_rest_api_id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_stage_name" {
  description = "The name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "api_gateway_deployment_id" {
  description = "The deployment ID of the API Gateway"
  value       = aws_api_gateway_deployment.this.id
}

output "api_gateway_invoke_url" {
  description = "The base URL for the API Gateway"
  value       = aws_api_gateway_stage.this.invoke_url
}
