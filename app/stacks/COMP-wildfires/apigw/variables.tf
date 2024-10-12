# This is where you put your variables declaration
variable "region" {
  description = "The AWS region to deploy the API Gateway"
  type        = string
  default     = "us-east-1"
}

variable "api_name" {
  description = "The name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "The description of the API Gateway"
  type        = string
  default     = "API Gateway created via Terraform"
}

variable "stage_name" {
  description = "The name of the stage to deploy"
  type        = string
  default     = "dev"
}

