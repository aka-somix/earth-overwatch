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
  type        = string
}

variable "ai_models_bucket" {
  type = object({
    name = string
    arn = string
  })
}
