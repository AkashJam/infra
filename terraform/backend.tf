# S3 backend, native state locking (Terraform 1.10+ `use_lockfile`) — no
# DynamoDB table, a deliberate simplification over portfolio.md §5/§10.2's
# "S3 + DynamoDB lock" phrasing (written before this feature existed).
#
# Backend config can't reference variables, so actual values (bucket, key,
# region, use_lockfile) come from -backend-config at init time:
#
#   terraform init -backend-config=environments/prod/backend.hcl
#
# The bucket itself comes from `terraform apply` in bootstrap/ (run once,
# with local state, before this backend can be initialized at all).
terraform {
  backend "s3" {}
}
