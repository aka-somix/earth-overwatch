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

variable "geodb_endpoint" {
  description = "Endpoint for reaching the common GeoDB"
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}
