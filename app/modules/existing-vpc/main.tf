# This is where you put your resource declaration
#
# VPC
#
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_tag]
  }
}

#
# SUBNETS
#
data "aws_subnet" "this" {
  filter {
    name   = "tag:Name"
    values = var.subnets_tag
  }
}
