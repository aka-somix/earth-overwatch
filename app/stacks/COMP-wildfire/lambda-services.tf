
module "lambda_service_fromsat" {
  source = "../../modules/lambda-node-api-service"

  function_name                = "${local.resprefix}-fromsat-service"
  architectures                = ["arm64"]
  lambda_service_resource_path = "fromsat"
  apigw_rest_api               = module.wildfire_apigw
  logs_retention_days          = 30
  memory_size                  = 128
  source_code_folder           = "./services/fromsat"
  handler                      = "dist/index.handler"
  timeout                      = 5
}
