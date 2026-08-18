variable "project_name" {
  type        = string
  description = "Short project name, used in the 'Name' tag the deploy role's ssm:SendCommand permission is scoped to."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. prod), used in the 'Name' tag."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. t4g.small (ARM/Graviton) per portfolio.md ADR-001 T1."
  default     = "t4g.small"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name from the iam module."
}

variable "data_volume_size_gb" {
  type        = number
  description = "Size of the separate EBS data volume (Postgres/Timescale storage, Days 5-9)."
  default     = 20
}
