#
# --- POLICIES ---
#
resource "aws_iam_policy" "send_events_backend" {
  name = "${local.resprefix}-send-events-to-be-ebus"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "events:PutEvents",
        "Resource" : "${var.backend_eventbus.arn}"
      }
    ]
  })
}

resource "aws_iam_policy" "sagemaker_invoke" {
  name = "${local.resprefix}-invoke-sagemaker-endpoint"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sagemaker:InvokeEndpoint",
        "Resource" : "arn:aws:sagemaker:${var.region}:${var.account_id}:endpoint/*"
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
  function_name       = "${local.resprefix}-ed-new-data-handler"
  architectures       = ["arm64"]
  handler             = "dist/index.handler"
  memory_size         = 256
  timeout             = 5
  logs_retention_days = 30
  # Source code
  source_code_folder     = "./ed-services/new-data-handler"
  lambda_packages_bucket = var.s3_bucket_lambda_packages

  # Global settings
  eventbridge_bus_arn = var.eventrule_new_data_from_aerial.arn

  # VPC Config
  vpc = {
    enabled            = true
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.subnet_ids
  }

  # ENV
  env_vars = {
    "EVENT_BUS_NAME"           = var.backend_eventbus.name
    "API_KEY"                  = data.aws_api_gateway_api_key.personal.value
    "MONITORING_API_BASE_PATH" = "${var.geo_apigw_endpoint}"
  }
}

resource "aws_iam_role_policy_attachment" "send_events_to_backend_bus" {
  role       = module.lambda_service_new_data_handler.iam_role.id
  policy_arn = aws_iam_policy.send_events_backend.arn
}

resource "aws_cloudwatch_event_target" "send_from_synth_data" {
  target_id      = "to-newdata-handler"
  arn            = module.lambda_service_new_data_handler.arn
  rule           = var.eventrule_new_image_data_from_synth.name
  event_bus_name = var.dataplatform_eventbus.name
}

# [END] NEW DATA HANDLER


# [START] DETECT LANDFILLS
module "lambda_detect_landfill" {
  source = "./tf-modules/lambda-node-ed-service"

  # Lambda Settings
  function_name       = "${local.resprefix}-ed-detect-landfill"
  architectures       = ["arm64"]
  handler             = "dist/index.handler"
  memory_size         = 128
  timeout             = 10
  logs_retention_days = 30
  # Source code
  source_code_folder     = "./ed-services/detect-landfill"
  lambda_packages_bucket = var.s3_bucket_lambda_packages

  # Eventbridge bus arn allowed 
  eventbridge_bus_arn = var.eventrule_be_detect_landfills.arn

  # ENV
  env_vars = {
    ENDPOINT_NAME = "scrnts-dev-landfill-yolo11-generic"
  }
}
# IAM POLICIES
resource "aws_iam_role_policy_attachment" "detect_landfill_s3_read" {
  role       = module.lambda_detect_landfill.iam_role.id
  policy_arn = var.aws_policy_landingzonebucket_readonly.arn
}
resource "aws_iam_role_policy_attachment" "detect_landfill_sagemaker_invoke" {
  role       = module.lambda_detect_landfill.iam_role.id
  policy_arn = aws_iam_policy.sagemaker_invoke.arn
}

# EVENT TARGET
resource "aws_cloudwatch_event_target" "new_data_to_detect" {
  target_id      = "to-detect-landfill"
  arn            = module.lambda_detect_landfill.arn
  rule           = var.eventrule_be_detect_landfills.name
  event_bus_name = var.backend_eventbus.name
}

# [END] DETECT LANDFILLS

