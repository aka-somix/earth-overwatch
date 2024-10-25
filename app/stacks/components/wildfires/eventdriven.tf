#
# --- LAMBDA EVENT-SERVICES ---
#
module "lambda_service_new_data_handler" {
  source = "./tf-modules/lambda-node-ed-service"
  
  # Lambda Settings
  function_name                = "${local.resprefix}-ed-new-data-handler"
  architectures                = ["arm64"]
  handler                      = "dist/index.handler"
  memory_size                  = 256
  timeout                      = 5
  logs_retention_days          = 30
  # Source code
  source_code_folder           = "./ed-services/new-data-handler"
  lambda_packages_bucket       = var.s3_bucket_lambda_packages

  # Global settings
  region = var.region
  account_id = var.account_id

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # ENV
  env_vars = {}
}

resource "aws_cloudwatch_event_target" "send_from_synth_data" {
  target_id = "to-newdata-handler"
  arn       = module.lambda_service_new_data_handler.arn
  rule            = var.eventrule_new_image_data_from_synth.name
  event_bus_name = var.dataplatform_eventbus.name
}
