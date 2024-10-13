locals {
  resprefix = "${var.project_name}-${var.env}-wildfire"
}

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

#
# --- DATABASE WILDFIRES ---
#
resource "random_password" "db_wildfires" {
  length  = 16
  special = true
  upper   = true
  lower   = true
}
module "wildfires_database" {
  source = "./tf-modules/aurora-serverless"

  cluster_name   = local.resprefix
  database_name  = "wildfires"
  engine_version = 15.4

  # Connectivity
  database_security_groups_ids = var.security_group_ids
  database_subnets_ids         = var.subnet_ids

  # Credentials
  username = "postgres"
  password = random_password.db_wildfires.result
}

#
# --- LAMBDA MICRO-SERVICES ---
#
module "lambda_service_fromsat" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-fromsat-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/fromsat"
  lambda_service_resource_path = "fromsat"
  memory_size                  = 128
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.wildfire_apigw.api
  lambda_packages_bucket       = "cicd-lambda-packages" # TODO Cambiare il bucket dei packages
}


