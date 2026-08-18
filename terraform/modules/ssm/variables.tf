variable "project_name" {
  type        = string
  description = "Short project name, used as the SSM parameter path prefix."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. prod), used as the SSM parameter path segment."
}
