#
# --- SAGE MAKER ENDPOINT
#

# TODO Waiting for the model to be ready

# resource "aws_sagemaker_endpoint_configuration" "landfill_detection" {
#   name = "${local.resprefix}-landfill-detection-config"

#   production_variants {
#     variant_name           = "AllTraffic"
#     model_name             = aws_sagemaker_model.landfill_detection.name
#     serverless_config {
#       memory_size_in_mb = 4096
#       max_concurrency   = 10
#     }
#   }
# }

# resource "aws_sagemaker_endpoint" "landfill_detection" {
#   name = "${local.resprefix}-landfill-detection"
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.landfill_detection.name
# }
