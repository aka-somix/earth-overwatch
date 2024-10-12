resource "aws_api_gateway_deployment" "wildfire" {
  rest_api_id = module.wildfire_apigw.api.id

  triggers = {
    // Deploy every time
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.lambda_service_fromsat]
}

resource "aws_api_gateway_stage" "env" {
  deployment_id = aws_api_gateway_deployment.wildfire.id
  rest_api_id   = module.wildfire_apigw.api.id
  stage_name    = var.env
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = module.wildfire_apigw.api.id
  stage_name  = aws_api_gateway_stage.env.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"

    throttling_burst_limit = 10000
    throttling_rate_limit  = 100
  }
}
