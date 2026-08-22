#!/bin/bash
# Nightly TimescaleDB backup (portfolio.md §15) — run via the host crontab
# installed by terraform/modules/ec2/main.tf's user_data, not a compose
# service (fewer moving parts, reuses the instance role's AWS credentials
# directly). Risk Register #2 already accepts ~24h data-loss exposure as
# the bound this needs to hit — no HA/point-in-time-recovery here, just a
# daily dump off the EBS volume it's taken from.
set -euo pipefail

cd /opt/app

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DUMP_FILE="/tmp/ticker-${TIMESTAMP}.dump"
BUCKET="portfolio-backups-$(aws sts get-caller-identity --query Account --output text)"

docker compose exec -T timescale pg_dump -U ticker -Fc ticker > "$DUMP_FILE"
aws s3 cp "$DUMP_FILE" "s3://${BUCKET}/${TIMESTAMP}.dump"
rm -f "$DUMP_FILE"
