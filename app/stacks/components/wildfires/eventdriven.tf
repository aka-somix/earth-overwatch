#
# --- EVENTBRIDGE POLICIES ---
#
resource "aws_iam_policy" "send_events_backend" {
  name = "${local.resprefix}-send-events-to-be-ebus"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "events:PutEvents",
        "Resource": "${var.backend_eventbus.arn}"
      }
    ]
  })
}

#
# --- LAMBDA EVENT-SERVICES ---
#

# [START] NEW DATA HANDLER
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

  attached_policies = [
    aws_iam_policy.send_events_backend.arn
  ]

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # ENV
  env_vars = {
    "EVENT_BUS_NAME"            = var.backend_eventbus.name
    "API_KEY"                   = data.aws_api_gateway_api_key.personal.value
    "MONITORING_API_BASE_PATH"  = var.geo_apigw_endpoint
  }
}

resource "aws_cloudwatch_event_target" "send_from_synth_data" {
  target_id = "to-newdata-handler"
  arn       = module.lambda_service_new_data_handler.arn
  rule            = var.eventrule_new_image_data_from_synth.name
  event_bus_name = var.dataplatform_eventbus.name
}

# [END] NEW DATA HANDLER

