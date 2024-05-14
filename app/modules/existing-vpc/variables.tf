# This is where you put your variables declaration
variable "vpc_tag" {
  type = string
}

variable "subnets_tag" {
  type = list(string)
}
