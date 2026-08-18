# Fill in `bucket` with the bootstrap module's `state_bucket` output once it
# has been applied (Phase B — needs a real AWS account, doesn't exist yet).
# No secrets in this file; safe to commit once filled in.
bucket       = "terraform-state-portfolio-149320913457"
key          = "prod/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
