locals {
  resprefix = "${var.project_name}-${var.env}"
}

module "models_bucket" {
  source = "./tf-modules/bucket"
  bucket_name = "${local.resprefix}-ai-models-${var.region}-${var.account_id}"
}
