# This is where you put your outputs declaration

output "rfa_labs_vpc" {
  value = data.aws_vpc.rfa_labs
}

output "rfa_labs_public_subnets" {
  value = data.aws_subnets.rfalabs_public
}
output "rfa_labs_dmz_subnets" {
  value = data.aws_subnets.rfalabs_dmz
}
output "rfa_labs_private_subnets" {
  value = data.aws_subnets.rfalabs_private
}
