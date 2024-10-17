locals {
  resprefix = "${var.project_name}-${var.env}-geo"
}

resource "random_password" "geodbpsw" {
  length  = 16
  special = true
  upper   = true
  lower   = true
}

module "geodb" {
  source = "./tf-modules/aurora-serverless"

  cluster_name   = local.resprefix
  database_name  = "geographical"
  engine_version = 15.4

  # Connectivity
  database_security_groups_ids = var.security_group_ids
  database_subnets_ids         = var.subnet_ids

  # Credentials
  username = "postgres"
  password = random_password.geodbpsw.result
}

resource "aws_security_group" "inbound_requests" {
  name = "${local.resprefix}-inbound-requests-sg"

  vpc_id = var.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc.cidr_block]
  }
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
# --- LAMBDA MICRO-SERVICES ---
#
module "lambda_service_monitor" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-monitor-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/monitor"
  lambda_service_resource_path = "monitor"
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
    "BASE_PATH"       = "monitor"
    "DATABASE_URL"    = ""
    "DATABASE_SECRET" = ""
  }
}