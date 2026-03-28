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

echo "==> Deploying temporary HTTP-only nginx config to obtain certificate"
cat > "$NGINX_CONF_DIR/bootstrap-temp.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/$DOMAIN;
    location / { try_files \$uri \$uri/ =404; }
}
EOF
ln -sf "$NGINX_CONF_DIR/bootstrap-temp.conf" "$NGINX_ENABLED_DIR/bootstrap-temp.conf"
rm -f "$NGINX_ENABLED_DIR/default"
nginx -t
systemctl reload nginx

echo "==> Obtaining SSL certificate"
certbot certonly \
  --webroot \
  --webroot-path /var/www/$DOMAIN \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

echo "==> Removing temporary config and deploying real nginx configs"
rm -f "$NGINX_ENABLED_DIR/bootstrap-temp.conf"
rm -f "$NGINX_CONF_DIR/bootstrap-temp.conf"

for conf in "$INFRA_DIR"/nginx/*.conf; do
  name=$(basename "$conf")
  [[ "$name" == _template* ]] && continue
  ln -sf "$conf" "$NGINX_CONF_DIR/$name"
  ln -sf "$NGINX_CONF_DIR/$name" "$NGINX_ENABLED_DIR/$name"
done

nginx -t
systemctl reload nginx

echo "==> Done. Visit https://$DOMAIN to verify."
