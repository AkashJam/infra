# v1 deliberately uses the account's default VPC (ADR-001 T1) — a dedicated
# VPC/subnets is a T2/§16.2 addition, not v1.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# 443 in only — no SSH port. Operator shell access is `aws ssm start-session`
# (AL2023 ships amazon-ssm-agent by default; the instance profile grants
# AmazonSSMManagedInstanceCore), matching §10.1/§13.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web"
  description = "Public HTTPS only; no SSH (SSM Session Manager instead)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

# Docker Engine + the Compose plugin only — deliberately does not bring up
# any containers at boot. What actually runs is entirely owned by
# infra/.github/workflows/deploy.yml (which syncs docker-compose.yml /
# Caddyfile from the releases S3 bucket and runs `docker compose up -d` over
# SSM), so there's exactly one place that decides what's running, not two.
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    mkdir -p /usr/local/lib/docker/cli-plugins
    COMPOSE_VERSION="v2.32.4"
    ARCH="$(uname -m)"
    curl -fsSL \
      "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-$${ARCH}" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    mkdir -p /opt/app

    # Days 5-9 (portfolio.md §15): format + mount the separate EBS data
    # volume (aws_ebs_volume.data below) for Timescale's data directory.
    # blkid-guarded so re-running user_data (or a future instance
    # replacement reusing this same script) never reformats a volume that
    # already has a filesystem — this only runs meaningfully on a genuinely
    # fresh volume. NOTE: user_data only executes on first boot — this has
    # no effect on an already-running instance; that needs the matching
    # one-time manual command run once via SSM Session Manager.
    if ! blkid /dev/xvdf; then
      mkfs -t xfs /dev/xvdf
    fi
    mkdir -p /mnt/data
    grep -q '/dev/xvdf' /etc/fstab || echo '/dev/xvdf /mnt/data xfs defaults,nofail 0 2' >> /etc/fstab
    mount -a
    # Just the mount point for the bind mount in docker-compose.yml — the
    # official Postgres/Timescale image's entrypoint fixes ownership of an
    # empty data directory itself (starts as root, chowns, then drops to
    # the postgres user), so no manual chown here.
    mkdir -p /mnt/data/timescale

    # Nightly backup (§15) — host crontab rather than a compose service:
    # fewer moving parts, reuses the instance role's AWS credentials
    # directly via `aws s3 sync`. /opt/app/backup.sh is delivered by
    # infra/.github/workflows/deploy.yml the same way docker-compose.yml is
    # — this cron entry is a no-op (logs an error, self-heals) until the
    # first successful deploy lands that file.
    dnf install -y cronie
    systemctl enable --now crond
    echo '0 3 * * * root /opt/app/backup.sh >> /var/log/ticker-backup.log 2>&1' > /etc/cron.d/ticker-backup
    chmod 644 /etc/cron.d/ticker-backup
  EOF
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023_arm64.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = var.instance_profile_name
  user_data              = local.user_data
  # Explicit, not left to the provider default: user_data changes (like this
  # phase's EBS-mount/backup-cron addition) only take effect on a FUTURE
  # instance replacement anyway (cloud-init runs user_data once, at first
  # boot) — this box is already live serving production traffic, and a
  # destroy+recreate is never the right response to a user_data-only diff.
  user_data_replace_on_change = false

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}

# Separate persistent volume for Postgres/Timescale data (Days 5-9) — kept
# apart from the root volume so it survives an instance replacement.
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.app.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"

  tags = {
    Name = "${var.project_name}-${var.environment}-data"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}
