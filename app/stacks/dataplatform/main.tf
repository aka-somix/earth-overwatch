locals {
  resprefix = "${var.project_name}-${var.env}-dataplat"
}

module "landing_zone_bucket" {
  source = "./tf-modules/bucket"

  bucket_name = "${local.resprefix}-landing-zone-${var.region}-${var.account_id}"
  destroyable = true
}

# Dinamically Exports Bucket name as parameter
resource "aws_ssm_parameter" "landinzonebucket" {
  name  = "/${var.env}/${var.project_name}/dataplat/landingzonebucket"
  type  = "String"
  value = module.landing_zone_bucket.name
}


module "ai_models_bucket" {
  source      = "./tf-modules/bucket"
  bucket_name = "${local.resprefix}-ai-models-${var.region}-${var.account_id}"
  destroyable = false
}

resource "aws_ssm_parameter" "aimodelsbucket" {
  name  = "/${var.env}/${var.project_name}/dataplat/aimodelsbucket"
  type  = "String"
  value = module.landing_zone_bucket.name
}
