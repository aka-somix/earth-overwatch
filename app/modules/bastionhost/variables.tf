# This is where you put your variables declaration

variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ssh_key_pair_name" {
  type = string
}

variable "vpc" {
  type = object({
    id         = string
    cidr_block = string
  })
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "desired_capacity" {
  type = number
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}
