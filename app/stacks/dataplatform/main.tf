locals {
  resprefix = "${var.project_name}-${var.env}-dataplat"
}

module "landing_zone_bucket" {
  source = "./tf-modules/bucket"

  bucket_name = "${local.resprefix}-landing-zone-${var.region}-${var.account_id}"
  destroyable = true
}
