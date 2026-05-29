#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOMAIN="${DOMAIN:-${NGINX_DOMAIN:-}}"

if [[ -z "${DOMAIN}" ]]; then
  echo "DOMAIN or NGINX_DOMAIN is required" >&2
  exit 1
fi

API_UPSTREAM="${API_UPSTREAM:-127.0.0.1:3000}"
TLS_CERT_PATH="${TLS_CERT_PATH:-/etc/letsencrypt/live/${DOMAIN}/fullchain.pem}"
TLS_KEY_PATH="${TLS_KEY_PATH:-/etc/letsencrypt/live/${DOMAIN}/privkey.pem}"
TEMPLATE="${TEMPLATE:-${ROOT_DIR}/deploy/nginx/memory-map.conf.template}"
OUTPUT="${OUTPUT:-${ROOT_DIR}/deploy/nginx/memory-map.conf}"

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst is required. Install gettext-base on Ubuntu/Debian." >&2
  exit 1
fi

export DOMAIN API_UPSTREAM TLS_CERT_PATH TLS_KEY_PATH
envsubst '$DOMAIN $API_UPSTREAM $TLS_CERT_PATH $TLS_KEY_PATH' < "${TEMPLATE}" > "${OUTPUT}"

echo "Rendered ${OUTPUT}"
