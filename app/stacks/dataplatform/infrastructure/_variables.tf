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
  description = "project prefix name"
  type        = string
}

variable "aerial_db_tables" {
  type = list(object({
    name = string
    path = string
    columns = list(any)
    partitions = list(any) 
  }))
}
