#!/usr/bin/env bash
# One-shot installer for Debian/Ubuntu. Run as root.
# Usage: bash deploy/setup.sh
set -euo pipefail

APP_DIR=/opt/seo-reranker
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Installing system packages (flask, requests, gunicorn, nginx, openpyxl)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y python3-flask python3-requests gunicorn nginx python3-openpyxl

echo "==> Copying app to $APP_DIR"
mkdir -p "$APP_DIR/templates"
cp "$REPO_DIR/app.py" "$APP_DIR/app.py"
cp "$REPO_DIR/templates/index.html" "$APP_DIR/templates/index.html"
cp "$REPO_DIR/serpiwi_auth.py" "$APP_DIR/serpiwi_auth.py"
mkdir -p "$APP_DIR/static" && cp "$REPO_DIR/static/"* "$APP_DIR/static/"

echo "==> Installing systemd service"
cp "$REPO_DIR/deploy/seo-reranker.service" /etc/systemd/system/seo-reranker.service
# Inject optional server-side default keys only if provided as env vars
for v in SERPER_KEY VOYAGE_API_KEY; do
  val="${!v:-}"
  [ -n "$val" ] && sed -i "/^\[Service\]/a Environment=\"$v=$val\"" /etc/systemd/system/seo-reranker.service
done

echo "==> Installing nginx site"
cp "$REPO_DIR/deploy/nginx.conf" /etc/nginx/sites-available/seo-reranker
ln -sf /etc/nginx/sites-available/seo-reranker /etc/nginx/sites-enabled/seo-reranker

echo "==> Starting services"
systemctl daemon-reload
systemctl enable --now seo-reranker
nginx -t && systemctl reload nginx

echo "==> Done. App is on http://<server-ip>/  (gunicorn on 127.0.0.1:8001)"
echo "    For HTTPS:  certbot --nginx -d your.domain.com --redirect"
