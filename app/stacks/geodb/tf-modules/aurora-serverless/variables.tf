variable "tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "engine_version" {
  type = number
}

variable "database_name" {
  type = string
}

variable "database_subnets_ids" {
  type = list(string)
}

variable "database_security_groups_ids" {
  type = list(string)
}

variable "min_capacity" {
  type    = number
  default = 0.5
}

variable "max_capacity" {
  type    = number
  default = 4
}
