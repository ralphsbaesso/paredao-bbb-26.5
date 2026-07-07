# syntax=docker/dockerfile:1
# check=error=true

# Imagem SSR de produção do frontend Nuxt 4.
# Build:  docker build -t paredao-frontend .
# Run:    docker run -d -p 3000:3000 -e NUXT_PUBLIC_API_BASE=<url> --name frontend paredao-frontend

# Base Debian/glibc (node:22-slim), NÃO Alpine/musl — evita falha dos binários
# nativos do @tailwindcss/oxide e do Rollup/oxc.
FROM node:22-slim AS base
WORKDIR /app
# Yarn 4 (Berry) habilitado via Corepack; versão fixada por packageManager.
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

# ---- Estágio de build: instala devDependencies e gera o artefato SSR (.output/) ----
FROM base AS build
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable
COPY . .
RUN yarn build

# ---- Estágio de runtime: imagem enxuta apenas com o .output/ ----
FROM base AS runtime
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000
# node:22-slim já traz o usuário `node` (uid/gid 1000) — espelha o padrão non-root do backend.
COPY --from=build --chown=node:node /app/.output ./.output
USER node
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
