variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "The registered domain (e.g. akjames.dev)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. t4g.small per portfolio.md ADR-001 T1."
  default     = "t4g.small"
}

variable "github_owner" {
  type        = string
  description = "GitHub account/org that owns the portfolio/ticker/infra repos."
}

variable "project_name" {
  type        = string
  description = "Short project name, used throughout resource naming."
  default     = "portfolio"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "prod"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource via the AWS provider's default_tags."
  default     = {}
}
