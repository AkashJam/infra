# Days 5-9 (portfolio.md §15): the Timescale DB password, generated here so
# no human ever types or sees it — deploy.yml fetches it at deploy time
# (aws ssm get-parameter --with-decryption) and passes it straight into
# docker-compose.yml's environment blocks (both `timescale`'s own
# POSTGRES_PASSWORD and `ticker`'s TIMESCALE_DSN, which embeds the same
# value) via shell interpolation, exactly like ECR_REGISTRY/IMAGE_TAG
# already work — the value never touches git or a file on disk.
#
# Alphanumeric-only (no `special`): a DSN's password segment isn't
# percent-encoded by docker-compose's variable substitution, so URI-special
# characters (@ / : # ? %) would silently corrupt the connection string.
# 32 alphanumeric characters is still ~190 bits of entropy.
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db-password"
  type  = "SecureString"
  value = random_password.db.result
}

# healthchecks.io check URL (§13 dead-man switch) is NOT managed here —
# Terraform can't know it in advance (it's created via the healthchecks.io
# web UI, a manual signup step), so it's set once via a plain
# `aws ssm put-parameter` CLI command instead. deploy.yml's fetch tolerates
# it not existing yet (empty HEALTHCHECKS_URL just means DeadMan.Ping is a
# no-op, per internal/ingest/deadman.go).
