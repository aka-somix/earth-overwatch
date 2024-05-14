variable "default_tags" {
  type = map(string)
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
}
