#
# --- API Gateway for COMPONENT ---
#
module "landfills_apigw" {
  source          = "./tf-modules/apigw"
  api_name        = "${local.resprefix}-api"
  api_description = "TBD"
  stage_name      = var.env
  region          = var.region
}


resource "aws_api_gateway_deployment" "landfills" {
  rest_api_id = module.landfills_apigw.api.id

  triggers = {
    // Deploy every time
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.lambda_service_detections
  ]
}

resource "aws_api_gateway_stage" "env" {
  deployment_id = aws_api_gateway_deployment.landfills.id
  rest_api_id   = module.landfills_apigw.api.id
  stage_name    = var.env
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = module.landfills_apigw.api.id
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
    api_id = module.landfills_apigw.api.id
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

# [START] DETECTIONS SERVICE
module "lambda_service_detections" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-api-detections-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/detections"
  lambda_service_resource_path = "detections"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.landfills_apigw.api
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # 
  env_vars = {
    "BASE_PATH"       = "detections"
    "DATABASE_URL"    = module.landfills_database.cluster.endpoint
    "DATABASE_SECRET" = module.landfills_database.credentials.id
  }
}

resource "aws_iam_role_policy_attachment" "events_detected_db_credentials_access" {
  policy_arn = aws_iam_policy.access_db_credentials.arn
  role       = module.lambda_service_detections.iam_role.id
}
# [END] DETECTIONS SERVICE
