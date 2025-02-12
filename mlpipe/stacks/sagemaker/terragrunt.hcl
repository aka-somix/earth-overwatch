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
    main_vpc = {
      id = "mock"
    },
    main_dmz_subnets = {ids = ["mock"]}

    outbound_to_everywhere_sg_id = "mock"
  }
}

inputs = {
  # module configuration variables
  account_id                  = get_aws_account_id()
  region                      = local.config.region.primary
  project_name                = local.config.project_name
  env                         = local.stage.env

  # ! ATTENTION !
  # !-----------!
  # ! Use This Flag if you want to create/destroy the notebook for experiments
  # ! THIS WILL COST EXTRA -> Check the pricing of the instance type specified in main.tf
  include_notebook            = false


  # Network Dependencies:
  vpc = dependency.network.outputs.main_vpc  
  subnets = dependency.network.outputs.main_dmz_subnets.ids
  security_group_ids = [dependency.network.outputs.outbound_to_everywhere_sg_id]
}
