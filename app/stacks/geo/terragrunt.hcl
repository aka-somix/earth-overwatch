include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))
}

dependency "network" {
  config_path = find_in_parent_folders("network")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    rfa_labs_vpc = {},
    rfa_labs_dmz_subnets = {ids = ["mock"]}
    inbound_from_vpc_sg_id = "string"
    outbound_to_vpc_sg_id = "string"
    outbound_to_everywhere_sg_id = "string"
  }
}

inputs = {
  # module configuration variables
  account_id                  = get_aws_account_id()
  region                      = local.config.region.primary
  project_name                = local.config.project_name
  env                         = local.stage.env

  api_key_id                  = local.stage.api_key_id
  s3_bucket_lambda_packages   = local.stage.s3_bucket_lambda_packages

  vpc                         = dependency.network.outputs.rfa_labs_vpc
  subnet_ids                  = dependency.network.outputs.rfa_labs_dmz_subnets.ids
  
  security_group_ids          = [
    dependency.network.outputs.inbound_from_vpc_sg_id
  ]

  lambda_security_group_ids = [
    dependency.network.outputs.outbound_to_vpc_sg_id,
    dependency.network.outputs.outbound_to_everywhere_sg_id
  ]
}
