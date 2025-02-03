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
    outbound_to_everywhere_sg_id = "mock"
  }
}


dependency "dataplatform" {
  config_path = find_in_parent_folders("dataplatform/infrastructure")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    landing_zone_bucket = { arn = "mock", name="mock"},
    aws_policy_landingzonebucket_writeread = { arn = "mock", id="mock"},
  }
}

inputs = {
  # module configuration variables
  account_id              = get_aws_account_id()
  region                  = local.config.region.primary
  project_name            = local.config.project_name
  env                     = local.stage.env

  # NETWORK DEPENDENCIES:
  ce_subnets_ids = dependency.network.outputs.rfa_labs_dmz_subnets.ids
  ce_security_groups_ids = [dependency.network.outputs.outbound_to_everywhere_sg_id]

  # DATAPLATFORM INFRASTRUCTURE DEPENDENICES:
  landing_zone_bucket = dependency.dataplatform.outputs.landing_zone_bucket
  aws_policy_landingzonebucket_writeread = dependency.dataplatform.outputs.aws_policy_landingzonebucket_writeread
}
