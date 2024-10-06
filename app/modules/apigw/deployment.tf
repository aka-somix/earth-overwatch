# Deployment for API Gateway - redeploys on every apply
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.stage_name

  # triggers = {
  #   redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this))
  # }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
}
