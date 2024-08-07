#
# SUBNETS
#
data "aws_subnet" "dmz0" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-dmz-subnet-0"]
  } 
}

data "aws_subnet" "dmz1" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-dmz-subnet-1"]
  } 
}

data "aws_subnet" "dmz2" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-dmz-subnet-2"]
  } 
}