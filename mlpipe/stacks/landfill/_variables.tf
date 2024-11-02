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

variable "sagemaker_execution_role" {
  type = object({
    arn = string
    id  = string
  })
}

variable "aws_s3_bucket_aimodels" {
  type = object({
    arn    = string
    bucket = string
  })
}
