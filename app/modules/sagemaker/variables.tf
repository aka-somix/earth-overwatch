# This is where you put your variables declaration
variable "domain_name" {
  type = string
}

variable "username" {
  type = string
}

variable "domain_role_name" {
  type = string
}

variable "forecast_role_name" {
  type = string
}

variable "sagemaker_image_arn" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC to deploy the domain into"
}

variable "subnet_ids" {
  type = list(string)
}

variable "sharing_settings_bucket" {
  type = object({
    id = string
    arn = string
  })
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
