# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS base
WORKDIR /app
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV PNPM_HOME=/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends ca-certificates openssl \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json apps/api/package.json
COPY apps/api apps/api
RUN pnpm install --frozen-lockfile

FROM deps AS build
RUN pnpm api:build
RUN pnpm --filter @memory-map/api deploy --prod --legacy /prod/api
RUN set -eux; \
  src_client="$(readlink -f /app/apps/api/node_modules/@prisma/client)"; \
  dest_client="$(readlink -f /prod/api/node_modules/@prisma/client)"; \
  src_prisma="$(dirname "$(dirname "$src_client")")/.prisma"; \
  dest_prisma="$(dirname "$(dirname "$dest_client")")/.prisma"; \
  cp -a "$src_prisma" "$dest_prisma"

FROM base AS runner
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=build /prod/api ./

EXPOSE 3000
CMD ["node", "dist/main.js"]
