terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

# Small artifact bucket the infra deploy workflow pushes docker-compose.yml
# / Caddyfile into, and the box pulls them from — fills a gap the doc leaves
# implicit ("ssm send-command: docker compose pull && up -d" doesn't say how
# the compose file itself gets onto the box).
resource "aws_s3_bucket" "releases" {
  bucket = "${var.project_name}-releases-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "releases" {
  bucket = aws_s3_bucket.releases.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Days 5-9 (portfolio.md §15): nightly pg_dump destination — off-volume
# durability, distinct from the EBS data volume the dumps are taken from.
# infra/backup.sh (run via the EC2 instance role's host crontab) writes
# here; nothing else reads from or writes to this bucket.
resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-backups-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Backups need no long memory at v1 scale (Risk Register #2 already accepts
# ~24h data-loss exposure as the actual bound, not "keep backups forever") —
# expire after 30 days so the bucket doesn't grow unbounded.
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }
  }
}

module "ecr" {
  source = "./modules/ecr"
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  github_owner        = var.github_owner
  ecr_repo_arns       = module.ecr.repository_arns
  releases_bucket_arn = aws_s3_bucket.releases.arn
  backups_bucket_arn  = aws_s3_bucket.backups.arn
}

module "ssm" {
  source = "./modules/ssm"

  project_name = var.project_name
  environment  = var.environment
}

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  instance_profile_name = module.iam.ec2_instance_profile_name
}

module "dns" {
  source = "./modules/dns"

  domain_name = var.domain_name
  eip_address = module.ec2.eip_address
}
