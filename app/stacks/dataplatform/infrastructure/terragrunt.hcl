include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))

  aerial_db_tables = yamldecode(file("./tables/aerial.yaml"))
}

inputs = {
  # module configuration variables
  account_id              = get_aws_account_id()
  region                  = local.config.region.primary
  project_name            = local.config.project_name
  env                     = local.stage.env

  aerial_db_tables        = local.aerial_db_tables
}
