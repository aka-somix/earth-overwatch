locals {
  resprefix = "${var.project_name}-${var.env}-geodb"
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
  database_name  = "geo"
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
