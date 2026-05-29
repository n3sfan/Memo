# Deployment Setup

## Docker Compose

1. Copy `.env.example` to `.env` and replace placeholder secrets.
2. Start the infrastructure:

```bash
docker compose up -d --build
```

The API is bound to `127.0.0.1:3000` by default so Nginx can reverse proxy to it without exposing the service directly.

## PM2 Cluster Mode

For a host-level PM2 deployment, build the API and start the cluster from the repository root:

```bash
pnpm install --frozen-lockfile
pnpm api:build
pm2 start apps/api/ecosystem.config.js --env production
pm2 save
```

The app tier must stay stateless. Session revocation and future cache state belong in Redis, not process memory.

## Nginx TLS Reverse Proxy

The template lives at `deploy/nginx/memory-map.conf.template`.

Render a config locally on the VPS:

```bash
DOMAIN=api.example.com \
API_UPSTREAM=127.0.0.1:3000 \
deploy/scripts/render-nginx-config.sh
```

Install it into Nginx:

```bash
DOMAIN=api.example.com deploy/scripts/install-nginx-site.sh
```

The default certificate paths assume Certbot/Let's Encrypt:

```text
/etc/letsencrypt/live/<domain>/fullchain.pem
/etc/letsencrypt/live/<domain>/privkey.pem
```
