variable "project_name" {
  type        = string
  description = "Short project name, used in resource names and the SSM parameter path this module grants read access to."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. prod). Used both in the SSM parameter path and as the EC2 'Name' tag value the deploy role's ssm:SendCommand permission is scoped to."
}

variable "github_owner" {
  type        = string
  description = "GitHub account/org that owns the three repos (e.g. AkashJam)."
}

variable "github_ci_repos" {
  type        = list(string)
  description = "Repos allowed to assume the CI role (ECR push only) — portfolio and ticker."
  default     = ["portfolio", "ticker"]
}

variable "github_deploy_repo" {
  type        = string
  description = "Repo allowed to assume the deploy role (ssm:SendCommand + release bucket write) — infra."
  default     = "infra"
}

variable "ecr_repo_arns" {
  type        = list(string)
  description = "ECR repository ARNs the CI role and the EC2 instance role may push/pull."
}

variable "releases_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket the deploy role writes docker-compose.yml/Caddyfile to, and the EC2 instance role reads them from."
}

variable "backups_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket infra/backup.sh (run via the EC2 instance role's host crontab) writes nightly pg_dump output to."
}
