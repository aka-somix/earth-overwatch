variable "stack_tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Current Environment"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "project" {
  description = "project prefix name"
  type        = string
}
