# This is where you put your variables declaration

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "bucket_tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}

variable "destroyable" {
  type = bool
  default = false
}