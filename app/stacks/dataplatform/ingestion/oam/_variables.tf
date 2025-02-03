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

variable "ce_subnets_ids" {
  type = list(string)
}

variable "ce_security_groups_ids" {
  type = list(string)
}

variable "landing_zone_bucket" {
  type = object({
    name = string
    arn  = string
  })
}

variable "aws_policy_landingzonebucket_writeread" {
  type = object({
    id  = string
    arn = string
  })
}
