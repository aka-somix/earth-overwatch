# This is where you put your outputs declaration

output "rfa_labs_vpc" {
  value = data.aws_vpc.rfa_labs
}

output "rfa_labs_public_subnet" {
  value = data.aws_subnets.rfalabs_public
}
output "rfa_labs_dmz_subnets" {
  value = data.aws_subnets.rfalabs_dmz
}
output "rfa_labs_private_subnets" {
  value = data.aws_subnets.rfalabs_private
}

output "inbound_from_vpc_sg_id" {
  value = aws_security_group.vpc_inbound_requests.id
}

output "outbound_to_vpc_sg_id" {
  value = aws_security_group.vpc_outbound_requests.id
}
