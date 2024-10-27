variable "env" {
  description = "Current Environment"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
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

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "lambda_security_group_ids" {
  type = list(string)
}

variable "eventrule_new_image_data_from_synth" {
  type = object({
    id = string
    name = string
  })
}

variable "dataplatform_eventbus" {
  type = object({
    id = string
    name = string
  })
}

variable "backend_eventbus" {
  type = object({
    id = string
    name = string
    arn = string
  })
}

variable "geo_apigw_endpoint" {
  type = string
  description = "Https Endpoint for calling the Geo APIGW"
}
