# This is where you put your variables declaration
variable "database_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "deletion_protection" {
  type = bool
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}

