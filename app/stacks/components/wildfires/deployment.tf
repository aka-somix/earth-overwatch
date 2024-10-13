resource "aws_api_gateway_deployment" "wildfire" {
  rest_api_id = module.wildfire_apigw.api.id

  triggers = {
    // Deploy every time
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.lambda_service_events_detected,
    module.lambda_service_feedback
  ]
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


#
# --- DEMO USAGE PLAN + API KEY ---
#

resource "aws_api_gateway_usage_plan" "demo" {
  name = local.resprefix
  api_stages {
    api_id = module.wildfire_apigw.api.id
    stage  = aws_api_gateway_stage.env.stage_name
  }
}
resource "aws_api_gateway_usage_plan_key" "demo" {
  key_id        = aws_api_gateway_api_key.demo.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.demo.id
}

resource "aws_api_gateway_api_key" "demo" {
  name    = "${local.resprefix}-demo-apikey"
  enabled = true
}
