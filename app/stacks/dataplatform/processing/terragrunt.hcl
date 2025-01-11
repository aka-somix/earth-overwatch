include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))
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
    aws_policy_landingzonebucket_readonly = { arn = "mock"}
  }
}

inputs = {
  # module configuration variables
  account_id              = get_aws_account_id()
  region                  = local.config.region.primary
  project_name            = local.config.project_name
  env                     = local.stage.env


  # EVENTS BROKER DEPENDENCIES:
  dataplatform_eventbus               = dependency.events-broker.outputs.dataplatform_eventbus
  backend_eventbus                    = dependency.events-broker.outputs.backend_eventbus
  eventrule_new_image_data_from_synth = dependency.events-broker.outputs.eventrule_new_image_data_from_synth
  eventrule_be_detect_landfills       = dependency.events-broker.outputs.eventrule_be_detect_landfills
  
  # DATAPLATFORM INFRASTRUCTURE DEPENDENICES:
  aws_policy_landingzonebucket_readonly = dependency.dataplatform.outputs.aws_policy_landingzonebucket_readonly
}
