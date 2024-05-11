locals {
  account_id = get_aws_account_id()
  
  config = yamldecode(file("../config/global.yaml"))

  global_tags = { for t in local.config.tags: t.key => t.value } 
  
  // Final default tags
  default_tags = local.global_tags
}


remote_state {
  backend = "s3"
  config = {
    encrypt             = true
    bucket              = "${local.config.repository_name}-${local.account_id}-tf-state"
    key                 = "${path_relative_to_include()}/terraform.tfstate"
    region              = local.config.region.primary
    dynamodb_table      = "${local.config.repository_name}-${local.account_id}-tf-state"
    s3_bucket_tags      = local.default_tags
    dynamodb_table_tags = local.default_tags
  }
}

terraform {
  source = "${path_relative_from_include()}/${path_relative_to_include()}"
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
    default = {}
  }

  provider "aws" {
    region = "${local.config.region.primary}"
    default_tags {
      tags = var.default_tags
    }
  }
  
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
