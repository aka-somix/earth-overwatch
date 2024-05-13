data "aws_caller_identity" "current" {}

locals {
  env        = "<%= Terraspace.env %>"
  region     = "eu-west-1"
  account_id = data.aws_caller_identity.current.account_id
  project    = "tesi-eg"
}
