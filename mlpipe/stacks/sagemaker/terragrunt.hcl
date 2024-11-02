include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))
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
}
