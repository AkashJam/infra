variable "aws_region" {
  type        = string
  description = "AWS region for the Terraform state bucket."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short project name, used to build the globally-unique state bucket name."
  default     = "portfolio"
}
