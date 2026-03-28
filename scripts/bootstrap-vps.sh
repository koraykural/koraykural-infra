#!/usr/bin/env bash
# Run once on a fresh VPS to install dependencies and configure nginx + SSL.
# Usage: bash bootstrap-vps.sh

set -euo pipefail

DOMAIN="koraykural.com"
EMAIL="koraykural99@gmail.com"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
INFRA_DIR="/var/www/infra"

echo "==> Installing packages"
apt-get update -qq
apt-get install -y nginx certbot python3-certbot-nginx git

echo "==> Creating web root for main domain"
mkdir -p /var/www/$DOMAIN

echo "==> Cloning infra repo"
if [ ! -d "$INFRA_DIR" ]; then
  git clone git@github.com:koraykural/koraykural-infra.git "$INFRA_DIR"
fi

echo "==> Symlinking nginx configs (skipping templates)"
for conf in "$INFRA_DIR"/nginx/*.conf; do
  name=$(basename "$conf")
  # skip template files
  [[ "$name" == _template* ]] && continue
  ln -sf "$conf" "$NGINX_CONF_DIR/$name"
  ln -sf "$NGINX_CONF_DIR/$name" "$NGINX_ENABLED_DIR/$name"
done
rm -f "$NGINX_ENABLED_DIR/default"

echo "==> Testing nginx config"
nginx -t

echo "==> Reloading nginx"
systemctl reload nginx

echo "==> Obtaining SSL certificate for main domain"
certbot certonly \
  --nginx \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

echo "==> Reloading nginx with SSL"
systemctl reload nginx

echo "==> Done. Visit https://$DOMAIN to verify."
