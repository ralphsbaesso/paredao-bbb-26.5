# Frontend — Paredão BBB 26.5

Frontend em **Nuxt 4** (SSR), estilizado com **Tailwind CSS 4** e gerenciado com
**Yarn 4** (Berry) via Corepack. Serviço desacoplado do backend — comunica-se com
ele apenas via API, cuja URL vem da env de runtime `NUXT_PUBLIC_API_BASE`.

## Requisitos

- **Node.js 22.x LTS** (≥ 22.12 — o Nuxt 4 usa `oxc-parser`, um módulo ESM que
  depende do `require(ESM)` habilitado por padrão a partir do Node 22.12).
- **Corepack** habilitado (`corepack enable`) — ele ativa o Yarn 4 fixado no campo
  `packageManager` do `package.json`. Não instalar o Yarn via npm global.

## Desenvolvimento

```bash
corepack enable          # ativa o Yarn 4 (uma vez por máquina)
yarn install             # instala as dependências
yarn dev                 # http://localhost:3000
```

A URL da API é lida de `NUXT_PUBLIC_API_BASE` (veja `.env.example`):

```bash
NUXT_PUBLIC_API_BASE=http://localhost:3001 yarn dev
```

## Build de produção (SSR)

```bash
yarn build                       # gera .output/ (preset Nitro node-server)
node .output/server/index.mjs    # sobe o servidor SSR
```

## Container (SSR)

Imagem multi-stage baseada em `node:22-slim`, rodando como usuário non-root (uid 1000).

```bash
docker build -t paredao-frontend .
docker run --rm -p 3000:3000 \
  -e NUXT_PUBLIC_API_BASE=https://api.exemplo.com \
  paredao-frontend
```

O container faz bind em `0.0.0.0:3000` e serve a aplicação renderizada no servidor.
Em SSR, o servidor Nuxt pode acessar o backend pela rede interna, enquanto o browser
usa a URL pública — os dois valores podem ser distintos.
