#!/usr/bin/env bash
# Pull latest infra config and reload nginx.
# Run on the VPS after pushing changes to this repo.

set -euo pipefail

INFRA_DIR="/var/www/infra"

echo "==> Pulling latest infra"
git -C "$INFRA_DIR" pull

echo "==> Testing nginx config"
nginx -t

echo "==> Reloading nginx"
systemctl reload nginx

echo "==> Done."
