# This is where you put your resource declaration

locals {
  resprefix = "${var.project}-${var.env}-${var.component}"
}

#
# --- API Gateway for COMPONENT ---
#
module "wildfire_apigw" {
  source          = "../../modules/apigw"
  api_name        = "${local.resprefix}-wildfire-api"
  api_description = "TBD"
}
