include {
  path = find_in_parent_folders()
}

locals {
  module = basename(get_terragrunt_dir())
  config = yamldecode(file("../../config/global.yaml"))
}

inputs = {
  # module configuration variables
  account_id = get_aws_account_id()
  region     = local.config.region.primary
  project    = local.config.project_name
  prefix     = "${local.config.project_name}-${local.module}"
}
