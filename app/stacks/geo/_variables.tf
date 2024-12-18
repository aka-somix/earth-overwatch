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

variable "api_key_id" {
  description = "the api key id for apigw"
  type        = string
}

variable "s3_bucket_lambda_packages" {
  type = string
}

variable "vpc" {
  type = object({
    id         = string
    cidr_block = string
  })
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "lambda_security_group_ids" {
  type = list(string)
}
