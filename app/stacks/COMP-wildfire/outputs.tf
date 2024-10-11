# This is where you put your outputs declaration

output "wildfire_api" {
  value = module.wildfire_apigw
}

output "api_gateway_deployment_id" {
  description = "The deployment ID of the API Gateway"
  value       = aws_api_gateway_deployment.wildfire.id
}

output "api_gateway_invoke_url" {
  description = "The base URL for the API Gateway"
  value       = aws_api_gateway_stage.env.invoke_url
}
