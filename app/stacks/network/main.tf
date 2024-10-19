# This is where you put your resource declaration
locals {
  resprefix = "${var.project_name}-${var.env}-network"
}

#
# VPC
#
data "aws_vpc" "rfa_labs" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-vpc"]
  }
}

#
# SUBNETS
#
data "aws_subnets" "rfalabs_public" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-public-subnet-0", "rfa-labs-public-subnet-1", "rfa-labs-public-subnet-2"]
  }
}

data "aws_subnets" "rfalabs_dmz" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-dmz-subnet-0", "rfa-labs-dmz-subnet-1", "rfa-labs-dmz-subnet-2"]
  }
}

data "aws_subnets" "rfalabs_private" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-private-subnet-0", "rfa-labs-private-subnet-1", "rfa-labs-private-subnet-2"]
  }
}

#
# SECURITY GROUPS
#

resource "aws_security_group" "vpc_inbound_requests" {
  name = "${local.resprefix}-inbound-from-vpc"

  vpc_id = data.aws_vpc.rfa_labs.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.rfa_labs.cidr_block]
  }

  tags = {
    "Name" = "[${local.resprefix}] VPC Inbound full permissions"
  }
}

resource "aws_security_group" "vpc_outbound_requests" {
  name = "${local.resprefix}-outbound-to-vpc"

  vpc_id = data.aws_vpc.rfa_labs.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.rfa_labs.cidr_block]
  }

  tags = {
    "Name" = "[${local.resprefix}] VPC Outbound full permissions"
  }
}

resource "aws_security_group" "everywhere_outbound_requests" {
  name = "${local.resprefix}-outbound-to-everywhere"

  vpc_id = data.aws_vpc.rfa_labs.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IPv4 traffic
  }

  # Allow all IPv6 outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"] # Allow all IPv6 traffic
  }
  tags = {
    "Name" = "[${local.resprefix}] VPC Egress full permissions"
  }
}
