# This is where you put your outputs declaration
output "vpc" {
  value = data.aws_vpc.this
}

output "subnet_ids" {
  value = data.aws_subnets.this.ids
}
