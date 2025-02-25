variable "env" {
  description = "Current Environment"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "project_name" {
  description = "project prefix name"
  type        = string
}

variable "account_id" {
  type = string
}

variable "include_notebook" {
  type    = bool
  default = false
}

variable "subnets" {
  type    = list(string)
}

variable "security_group_ids" {
  type    = list(string)
}
