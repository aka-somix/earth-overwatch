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

# FEATURE FLAG for Notebook eraser
variable "notebook_eraser_flag" {
  type = bool
}
