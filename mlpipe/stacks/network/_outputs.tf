# This is where you put your outputs declaration

output "main_vpc" {
  value = data.aws_vpc.main
}

output "main_public_subnet" {
  value = data.aws_subnets.main_public
}
output "main_dmz_subnets" {
  value = data.aws_subnets.main_dmz
}
output "main_private_subnets" {
  value = data.aws_subnets.main_private
}
output "outbound_to_everywhere_sg_id" {
  value = data.aws_security_group.outbound_everywhere.id
}