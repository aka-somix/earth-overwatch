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
  lambda_packages_bucket       = "cicd-lambda-packages" # TODO Cambiare il bucket dei packages

  # VPC Config
  vpc = {
    enabled            = false
    security_group_ids = []
    subnet_ids         = []
  }

  # 
  env_vars = {
    "BASE_PATH"       = "events"
    "DATABASE_URL"    = ""
    "DATABASE_SECRET" = ""
  }
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
  lambda_packages_bucket       = "cicd-lambda-packages" # TODO Cambiare il bucket dei packages

  # VPC Config
  vpc = {
    enabled            = false
    security_group_ids = []
    subnet_ids         = []
  }

  # 
  env_vars = {
    "BASE_PATH"       = "feedback"
    "DATABASE_URL"    = ""
    "DATABASE_SECRET" = ""
  }
}
