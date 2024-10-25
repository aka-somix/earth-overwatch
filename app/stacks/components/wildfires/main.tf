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

# Policy for accessing credentials
resource "aws_iam_policy" "access_db_credentials" {
  name        = "${local.resprefix}-access-credentials"
  description = "Policy to allow access to retrieve and decrypt Wildfires DB credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "${module.wildfires_database.credentials.arn}"
      }
    ]
  })
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
