#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_NAME="${SITE_NAME:-memory-map}"
RENDERED="${RENDERED:-/tmp/${SITE_NAME}.conf}"

OUTPUT="${RENDERED}" "${ROOT_DIR}/deploy/scripts/render-nginx-config.sh"

sudo install -m 0644 "${RENDERED}" "/etc/nginx/sites-available/${SITE_NAME}.conf"
sudo ln -sfn "/etc/nginx/sites-available/${SITE_NAME}.conf" "/etc/nginx/sites-enabled/${SITE_NAME}.conf"
sudo nginx -t
sudo systemctl reload nginx

echo "Installed and reloaded nginx site ${SITE_NAME}"
