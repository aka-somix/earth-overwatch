# This is where you put your resource declaration
locals {
  resprefix = "${var.project_name}-${var.env}-network"
}

#
# VPC
#
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_prefix_tag}-vpc"]
  }
}

#
# SUBNETS
#
data "aws_subnets" "main_public" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_prefix_tag}-public-subnet-0", "${var.vpc_prefix_tag}-public-subnet-1", "${var.vpc_prefix_tag}-public-subnet-2"]
  }
}

data "aws_subnets" "main_dmz" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_prefix_tag}-dmz-subnet-0", "${var.vpc_prefix_tag}-dmz-subnet-1", "${var.vpc_prefix_tag}-dmz-subnet-2"]
  }
}

data "aws_subnets" "main_private" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_prefix_tag}-private-subnet-0", "${var.vpc_prefix_tag}-private-subnet-1", "${var.vpc_prefix_tag}-private-subnet-2"]
  }
}

# FROM APP Stack
data "aws_security_group" "outbound_everywhere" {
  name = "${var.project_name}-${var.env}-network-outbound-to-everywhere"
}
