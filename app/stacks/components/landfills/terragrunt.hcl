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

dependency "geo" {
  config_path = find_in_parent_folders("geo")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    geo_apigw_endpoint = "mock"
  }
}

dependency "dataplatform" {
  config_path = find_in_parent_folders("dataplatform")

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

  api_key_id                  = local.stage.api_key_id
  s3_bucket_lambda_packages   = local.stage.s3_bucket_lambda_packages


  # NETWORK DEPENDENCIES
  vpc                     = dependency.network.outputs.rfa_labs_vpc
  subnet_ids              = dependency.network.outputs.rfa_labs_dmz_subnets.ids
  security_group_ids      = [
    dependency.network.outputs.inbound_from_vpc_sg_id
  ]

  lambda_security_group_ids = [
    dependency.network.outputs.outbound_to_vpc_sg_id,
    dependency.network.outputs.outbound_to_everywhere_sg_id
  ]

  # EVENTS BROKER DEPENDENCIES:
  dataplatform_eventbus               = dependency.events-broker.outputs.dataplatform_eventbus
  backend_eventbus                    = dependency.events-broker.outputs.backend_eventbus
  eventrule_new_image_data_from_synth = dependency.events-broker.outputs.eventrule_new_image_data_from_synth
  eventrule_be_detect_landfills       = dependency.events-broker.outputs.eventrule_be_detect_landfills

  # GEO MODULE DEPENDENICES:
  geo_apigw_endpoint = dependency.geo.outputs.geo_apigw_endpoint
  
  # DATAPLATFORM MODULE DEPENDENICES:
  aws_policy_landingzonebucket_readonly = dependency.dataplatform.outputs.aws_policy_landingzonebucket_readonly
}
