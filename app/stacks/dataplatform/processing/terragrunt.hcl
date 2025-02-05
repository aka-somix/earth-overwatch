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

dependency "events-broker" {
  config_path = find_in_parent_folders("events-broker")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    eventrule_new_image_data_from_synth = {
      id = "mock",
      arn = "mock",
      name = "mock"
    },
    eventrule_be_detect_landfills = {
      id = "mock",
      arn = "mock",
      name = "mock"
    },
    dataplatform_eventbus = {
      id = "mock",
      arn = "mock",
      name = "mock"
    },
    backend_eventbus = {
      id = "mock",
      arn = "mock",
      name = "mock"
    },
  }
}

dependency "dataplatform" {
  config_path = find_in_parent_folders("dataplatform/infrastructure")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    landing_zone_bucket = { arn = "mock", name="mock"},
    refined_zone_bucket = { arn = "mock", name="mock"},
    aws_policy_landingzonebucket_readonly = { arn = "mock", id="mock"},
    aws_policy_redefinedzone_writeread = { arn = "mock", id="mock"},
  }
}

inputs = {
  # module configuration variables
  account_id              = get_aws_account_id()
  region                  = local.config.region.primary
  project_name            = local.config.project_name
  env                     = local.stage.env
  aws_s3_bucket_glue_packages_name = local.stage.aws_s3_bucket_glue_packages_name

  # NETWORK DEPENDENCIES:
  ce_subnets_ids = dependency.network.outputs.rfa_labs_dmz_subnets.ids
  ce_security_groups_ids = [dependency.network.outputs.outbound_to_everywhere_sg_id]

  # EVENTS BROKER DEPENDENCIES:
  dataplatform_eventbus               = dependency.events-broker.outputs.dataplatform_eventbus
  backend_eventbus                    = dependency.events-broker.outputs.backend_eventbus
  eventrule_new_image_data_from_synth = dependency.events-broker.outputs.eventrule_new_image_data_from_synth
  eventrule_be_detect_landfills       = dependency.events-broker.outputs.eventrule_be_detect_landfills
  
  # DATAPLATFORM INFRASTRUCTURE DEPENDENICES:
  landing_zone_bucket = dependency.dataplatform.outputs.landing_zone_bucket
  refined_zone_bucket = dependency.dataplatform.outputs.refined_zone_bucket
  aws_policy_landingzonebucket_readonly = dependency.dataplatform.outputs.aws_policy_landingzonebucket_readonly
  aws_policy_redefinedzone_writeread = dependency.dataplatform.outputs.aws_policy_redefinedzone_writeread
  aws_policy_aerial_db_access = dependency.dataplatform.outputs.aws_policy_aerial_db_access
}
