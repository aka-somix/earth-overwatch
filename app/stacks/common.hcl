locals {
  config = yamldecode(file(find_in_parent_folders("config.yaml"))) # <----- Points to the config file
  stage   = yamldecode(file("../config/${get_env("ENV", "dev")}.yaml")) # <---- DEFAULTS TO DEV

  default_tags = { for t in local.config.tags: t.key => t.value } 
}


remote_state {
  backend = "s3"
  config = {
    encrypt             = true
    bucket              = "${local.stage.env}-${local.config.project_name}-terraform-state"
    key                 = "${path_relative_to_include()}/${local.config.repository_name}/terraform.tfstate"
    region              = local.config.region.primary
    dynamodb_table      = "${local.stage.env}-${local.config.repository_name}-terraform-state"
    s3_bucket_tags      = local.default_tags
    dynamodb_table_tags = local.default_tags
  }
}

terraform {
  source = "."
}

// Inputs for the Provider
inputs = {
    default_tags = local.default_tags
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF

  variable default_tags {
    type = map
  }

  provider "aws" {
    region = "${local.config.region.primary}"
    default_tags {
      tags = var.default_tags
    }
  }

  // provider "aws_failover_1" {
  //   region = "${local.config.region.failover-1}"
  //   default_tags {
  //     tags = var.default_tags
  //   }
  // }
  
  EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  terraform {
    backend "s3" {}
  }
  EOF
}