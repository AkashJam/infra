# infra deploy-plane dev container (portfolio.md §5, §10).
#
# infra/ has no production image (it owns Terraform, docker-compose, Caddy) —
# so this dev-only Dockerfile lives inside .devcontainer/. It is intentionally
# thin: Terraform, AWS CLI, Node, and the Docker CLI are layered on as
# devcontainer Features (see devcontainer.json), pinned in one declarative place.
#
# Base: Ubuntu 24.04 LTS devcontainer image — git, build tools, pre-wired
# non-root `vscode` user. Same neutral multi-tool base as the root container.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      make \
      jq \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*
