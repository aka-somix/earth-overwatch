variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "memory_size" {
  description = "The amount of memory available to the Lambda function in MB."
  type        = number
  default     = 128 # You can set a default value, or remove this line if no default is needed
}

variable "architectures" {
  description = "The instruction set architecture for the Lambda function (e.g., 'x86_64' or 'arm64')."
  type        = list(string)
}

variable "handler" {
  description = "The function within your code that Lambda calls to begin execution (e.g., 'index.handler')."
  type        = string
}

variable "timeout" {
  description = "The amount of time (in seconds) that Lambda allows a function to run before stopping it."
  type        = number
  default     = 3 # Optional default value
}

variable "vpc" {
  description = "VPC configuration for Lambda. VPC networking is optional."
  type = object({
    enabled            = bool
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
  })
  default = {
    enabled            = false
    subnet_ids         = []
    security_group_ids = []
  }
}

variable "env_vars" {
  description = "Environment variables for the Lambda function."
  type        = map(string)
  default     = {} # Optional default value, an empty map
}

variable "source_code_folder" {
  description = "The local folder where the Lambda source code is stored."
  type        = string
}

variable "logs_retention_days" {
  description = "The number of days to retain logs in CloudWatch Log Group."
  type        = number
  default     = 30 # You can change the default retention days or remove this line
}

variable "lambda_packages_bucket" {
  description = "The bucket for lambda packages"
  type        = string
}

variable "attached_policies" {
  description = "A list of IAM policy ARNs to attach to the Lambda execution role."
  type        = list(string)
  default     = []
}

variable "eventbridge_bus_arn" {
  description = "Eventbridge Bus to be allowed"
  type        = string
}
