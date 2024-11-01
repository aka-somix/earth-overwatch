
data "aws_vpc" "rfa_labs" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-vpc"]
  }
}

data "aws_subnets" "rfalabs_dmz" {
  filter {
    name   = "tag:Name"
    values = ["rfa-labs-dmz-subnet-0", "rfa-labs-dmz-subnet-1", "rfa-labs-dmz-subnet-2"]
  }
}

data "aws_security_group" "outbound_everywhere" {
  name = "${var.project_name}-${var.env}-network-outbound-to-everywhere"
}
