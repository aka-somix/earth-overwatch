data "aws_caller_identity" "current" {}

locals {
  prefix = var.project
}

module "datasets" {
  source      = "../../modules/simple-bucket"
  bucket_name = "${local.prefix}-datasets-${data.aws_caller_identity.current.account_id}-${var.region}"
  tags        = var.stack_tags
}
