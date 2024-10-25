#
# --- API Gateway for COMPONENT ---
#
module "wildfire_apigw" {
  source          = "./tf-modules/apigw"
  api_name        = "${local.resprefix}-api"
  api_description = "TBD"
  stage_name      = var.env
  region          = var.region
}


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
  key_id        = data.aws_api_gateway_api_key.personal.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.demo.id
}

data "aws_api_gateway_api_key" "personal" {
  id = var.api_key_id
}

#
# --- LAMBDA MICRO-SERVICES ---
#
module "lambda_service_events_detected" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-events-detected-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/events-detected"
  lambda_service_resource_path = "events"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.wildfire_apigw.api
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # 
  env_vars = {
    "BASE_PATH"       = "events"
    "DATABASE_URL"    = module.wildfires_database.cluster.endpoint
    "DATABASE_SECRET" = module.wildfires_database.credentials.id
  }
}

resource "aws_iam_role_policy_attachment" "events_detected_db_credentials_access" {
  policy_arn = aws_iam_policy.access_db_credentials.arn
  role       = module.lambda_service_events_detected.iam_role.id
}

module "lambda_service_feedback" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-feedback-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/feedback"
  lambda_service_resource_path = "feedback"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.wildfire_apigw.api
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # 
  env_vars = {
    "BASE_PATH"       = "feedback"
    "DATABASE_URL"    = module.wildfires_database.cluster.endpoint
    "DATABASE_SECRET" = module.wildfires_database.credentials.id
  }
}

resource "aws_iam_role_policy_attachment" "feedback_db_credentials_access" {
  policy_arn = aws_iam_policy.access_db_credentials.arn
  role       = module.lambda_service_feedback.iam_role.id
}
