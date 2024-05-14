# This is where you put your outputs declaration
output "vpc" {
  value = data.aws_vpc.this[0]
}

output "subnets" {
  value = data.aws_subnet.this
}
