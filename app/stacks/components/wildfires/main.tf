locals {
  resprefix = "${var.project_name}-${var.env}-wildfire"
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
