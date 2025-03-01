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
  
  engine_version = 16.3
  min_capacity = 0

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

# Policy for accessing credentials
resource "aws_iam_policy" "access_db_credentials" {
  name        = "${local.resprefix}-access-credentials"
  description = "Policy to allow access to retrieve and decrypt GEO DB credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "${module.geodb.credentials.arn}"
      }
    ]
  })
}


#
# --- API Gateway for COMPONENT ---
#
module "geo_data_apigw" {
  source          = "./tf-modules/apigw"
  api_name        = "${local.resprefix}-api"
  api_description = "TBD"
  stage_name      = var.env
  region          = var.region
}

#
# --- LAMBDA MICRO-SERVICES ---
#

# [START] GEO SERVICE
module "lambda_service_geo_data" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-data-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/geo"
  lambda_service_resource_path = "geo"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.geo_data_apigw.api
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # 
  env_vars = {
    "BASE_PATH"       = "geo"
    "DATABASE_URL"    = module.geodb.cluster.endpoint
    "DATABASE_SECRET" = module.geodb.credentials.name
  }
}

resource "aws_iam_role_policy_attachment" "geo_db_credentials_access" {
  policy_arn = aws_iam_policy.access_db_credentials.arn
  role       = module.lambda_service_geo_data.iam_role.id
}
# [END] GEO SERVICE


# [START] MONITOR SERVICE
module "lambda_service_monitor" {
  source = "./tf-modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-monitor-service"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  source_code_folder           = "./api-services/monitor"
  lambda_service_resource_path = "monitoring"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  apigw_rest_api               = module.geo_data_apigw.api
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # 
  env_vars = {
    "BASE_PATH"       = "monitoring"
    "DATABASE_URL"    = module.geodb.cluster.endpoint
    "DATABASE_SECRET" = module.geodb.credentials.name
  }
}
resource "aws_iam_role_policy_attachment" "monitor_db_credentials_access" {
  policy_arn = aws_iam_policy.access_db_credentials.arn
  role       = module.lambda_service_monitor.iam_role.id
}
# [END] MONITOR SERVICE

