# This is where you put your resource declaration

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
