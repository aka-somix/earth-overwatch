include {
  path   = find_in_parent_folders("common.hcl")
}

locals{
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
  stage   = yamldecode(file(find_in_parent_folders("config/${get_env("ENV", "dev")}.yaml")))
}

dependency "sagemaker" {
  config_path = find_in_parent_folders("sagemaker")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    sagemaker_execution_role = {
      arn = "mock"
      id = "mock"
    }

    aws_s3_bucket_aimodels = {
      arn = "mock"
      bucket = "mock"
    }
  }
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
  }
}


dependency "storage" {
  config_path = find_in_parent_folders("storage")

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_with_state = contains(["init", "validate", "plan"], get_terraform_command()) ? true : false
  mock_outputs = {
    datasets_efs = {
      arn = "mock"
      file_system_id = "mock"
    }
    datasets_mount_path = "mock"
  }
}

inputs = {
  # module configuration variables
  account_id                  = get_aws_account_id()
  region                      = local.config.region.primary
  project_name                = local.config.project_name
  env                         = local.stage.env

  landfill_dataset_folder     = local.stage.landfill.dataset_folder_name

  # Sagemaker Dependencies:
  sagemaker_execution_role = dependency.sagemaker.outputs.sagemaker_execution_role
  aws_s3_bucket_aimodels = dependency.sagemaker.outputs.aws_s3_bucket_aimodels

  # Network Dependencies:
  vpc = dependency.network.outputs.main_vpc  
  subnets = dependency.network.outputs.main_dmz_subnets.ids

  # Storage Dependencies:
  datasets_efs = dependency.storage.outputs.datasets_efs
  datasets_mount_path = dependency.storage.outputs.datasets_mount_path
}
