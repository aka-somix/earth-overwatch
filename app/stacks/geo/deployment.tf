resource "aws_api_gateway_deployment" "this" {
  rest_api_id = module.geo_data_apigw.api.id

  triggers = {
    // Deploy every time
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.lambda_service_monitor,
    module.lambda_service_geo_data,
  ]
}

resource "aws_api_gateway_stage" "env" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = module.geo_data_apigw.api.id
  stage_name    = var.env
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = module.geo_data_apigw.api.id
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
    api_id = module.geo_data_apigw.api.id
    stage  = aws_api_gateway_stage.env.stage_name
  }
}
resource "aws_api_gateway_usage_plan_key" "demo" {
  key_id        = data.aws_api_gateway_api_key.personal.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.demo.id
}

data "aws_api_gateway_api_key" "personal" {
  id = var.api_key_id
}
