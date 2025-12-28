#!/bin/bash
set -e

read -p "Enter domain/subdomain (without http/https): " DOMAIN

CONF="/etc/nginx/sites-available/$DOMAIN"

echo "[INFO] Creating Nginx config..."

cat > "$CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/node;
    index index.html;

    location / {
        return 403;
    }
}
EOF

ln -sf "$CONF" /etc/nginx/sites-enabled/
systemctl reload nginx

echo "[INFO] Requesting SSL..."
certbot --nginx -d "$DOMAIN"

echo "[OK] SSL created successfully"
