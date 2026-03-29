#!/usr/bin/env bash
# Pull latest infra config and reload nginx.
# Run on the VPS after pushing changes to this repo.

set -euo pipefail

INFRA_DIR="/var/www/infra"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

echo "==> Pulling latest infra"
git -C "$INFRA_DIR" pull

echo "==> Symlinking new nginx configs (skipping templates)"
for conf in "$INFRA_DIR"/nginx/*.conf; do
  name=$(basename "$conf")
  [[ "$name" == _template* ]] && continue
  sudo ln -sf "$conf" "$NGINX_CONF_DIR/$name"
  sudo ln -sf "$NGINX_CONF_DIR/$name" "$NGINX_ENABLED_DIR/$name"
done

echo "==> Testing nginx config"
sudo nginx -t

echo "==> Reloading nginx"
sudo systemctl reload nginx

echo "==> Done."
