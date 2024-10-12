locals {
  resprefix = "${var.project_name}-${var.env}-wildfire"
}

#
# --- API Gateway for COMPONENT ---
#
module "wildfire_apigw" {
  source          = "./apigw"
  api_name        = "${local.resprefix}-api"
  api_description = "TBD"
  stage_name      = var.env
  region          = var.region
}

#
# --- LAMBDA MICRO-SERVICES ---
#
module "lambda_service_fromsat" {
  source = "./lambda-node-api-service"

  function_name                = "${local.resprefix}-fromsat-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/fromsat"
  lambda_service_resource_path = "fromsat"
  memory_size                  = 128
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.wildfire_apigw.api
  lambda_packages_bucket       = "cicd-lambda-packages"
}

