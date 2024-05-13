variable "default_tags" {
  type = map(string)
}


provider "aws" {
  region = local.region
  default_tags {
    tags = var.default_tags
  }
}
