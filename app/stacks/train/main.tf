# This is where you put your resource declaration
data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.project}-training1"
}

module "sharing_settings" {
  source      = "../../modules/simple-bucket"
  bucket_name = "${local.prefix}-sagemaker-settings-${data.aws_caller_identity.current.account_id}-${var.region}"
  tags        = var.stack_tags
}

module "vpc" {
  source      = "../../modules/existing-vpc"
  vpc_tag     = "rfa-labs-vpc"
  subnets_tag = ["rfa-labs-dmz-subnet-0", "rfa-labs-dmz-subnet-1", "rfa-labs-dmz-subnet-2"]
}

module "sagemaker" {
  source             = "../../modules/sagemaker"
  domain_name        = "${local.prefix}-sgmk-domain"
  username           = "${local.prefix}-test-user"
  domain_role_name   = "${local.prefix}SageMakerDomainRole"
  forecast_role_name = "${local.prefix}SageMakerForecastRole"

  sagemaker_image_arn = "arn:aws:sagemaker:eu-west-1:470317259841:image/jupyter-server-3"

  sharing_settings_bucket = module.sharing_settings.bucket

  subnet_ids = module.vpc.subnet_ids
  vpc_id     = module.vpc.vpc.id
}

#
# STUDIO APP Associated
resource "aws_sagemaker_app" "studio" {
  domain_id         = module.sagemaker.sagemaker_domain.id
  user_profile_name = module.sagemaker.sagemaker_user.user_profile_name
  app_name          = "${local.prefix}-studio"
  app_type          = "JupyterServer"
}
