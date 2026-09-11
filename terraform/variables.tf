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

  # 2026-09 incident: running `terraform apply` without -var-file skipped
  # prod.tfvars entirely, and since this variable has no default, Terraform
  # prompted interactively — an email address got typed in by mistake and
  # silently became part of the OIDC trust policy's sub condition, breaking
  # every deploy. GitHub usernames/orgs can never contain "@" (see the
  # matching comment in modules/iam/main.tf), so reject it here at plan
  # time instead of failing much later inside AWS's OIDC token validation.
  validation {
    condition     = !strcontains(var.github_owner, "@")
    error_message = "github_owner must be a GitHub username/org (e.g. \"AkashJam\"), not an email address."
  }
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
