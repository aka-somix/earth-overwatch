include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))
}

dependency "main" {
  config_path = find_in_parent_folders("main")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    ai_models_bucket = {arn="", name=""},
  }
}


inputs = {
  # module configuration variables
  account_id                  = get_aws_account_id()
  region                      = local.config.region.primary
  project_name                = local.config.project_name
  env                         = local.stage.env

  # MAIN DEPENDENCIES
  ai_models_bucket              = dependency.main.outputs.ai_models_bucket

}
