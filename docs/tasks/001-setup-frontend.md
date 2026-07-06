# 001 - Setup do Frontend

## Contexto
O frontend do projeto **Paredão BBB 26.5** deve ser um serviço totalmente
desacoplado do backend, comunicando-se com ele exclusivamente via API. Toda a
base de código do frontend ficará isolada no diretório `frontend/`, localizado
na raiz do repositório.

## Objetivo
Realizar o setup inicial do frontend, deixando o projeto Nuxt executável em
ambiente de desenvolvimento **e conteinerizável para produção**, com estilização
via Tailwind CSS configurada e pronta para uso.

O frontend rodará **dentro de um container**, em modo de renderização
**SSR (Server-Side Rendering)** — ou seja, a imagem final executa um servidor
Node (`node .output/server/index.mjs`), não apenas arquivos estáticos.

## Tecnologias
As versões abaixo refletem as releases estáveis mais recentes (julho/2026).
Sempre que possível, utilizar a última versão estável disponível no momento da
instalação.

| Tecnologia | Versão alvo | Observação |
|------------|-------------|------------|
| [Nuxt](https://nuxt.com) | **4.x** (última estável, ex. `4.4.8`) | Framework principal; modo **SSR** (default), preset Nitro `node-server` |
| [Tailwind CSS](https://tailwindcss.com) | **4.x** (última estável, ex. `4.3.2`) | Integrar via plugin Vite oficial `@tailwindcss/vite` (padrão do v4) |
| [Yarn](https://yarnpkg.com) | **4.x** (Berry, última estável, ex. `4.17.0`) | Gerenciador obrigatório (não usar npm/pnpm), via **Corepack** |
| Node.js | **22.x LTS** (Node 20+ mínimo p/ Nuxt 4) | Base da imagem: `node:22-slim` (Debian/glibc) |

## Requisitos
1. Criar o projeto Nuxt dentro do diretório `frontend/` na raiz do repositório.
2. Configurar o **Yarn** como gerenciador de pacotes do projeto
   (definir `packageManager` no `package.json`).
3. Integrar e configurar o **Tailwind CSS**, garantindo que classes utilitárias
   funcionem em uma página de exemplo.
4. Manter o frontend desacoplado do backend (sem dependências diretas de código
   do backend). A URL da API deve vir de **variável de ambiente em runtime**
   (`NUXT_PUBLIC_API_BASE` via `runtimeConfig.public`), nunca hardcoded no build.
5. Entregar o setup **conteinerizado** (ver seção Conteinerização).

## Conteinerização (SSR)

O frontend deve rodar em container executando o servidor SSR do Nuxt. Os pontos
abaixo são **obrigatórios** — sem eles o container builda mas não funciona.

### Pontos de conflito já mapeados (devem ser tratados)

| # | Ponto | Resolução exigida |
|---|-------|-------------------|
| 1 | Bind de rede | Definir `HOST=0.0.0.0` e `PORT=3000` no container. O default (`localhost`) **não é acessível de fora do container**. |
| 2 | Yarn 4 via Corepack | Habilitar com `corepack enable`; versão fixada por `packageManager` no `package.json`. Não instalar Yarn via npm global. |
| 3 | Linker do Yarn Berry | Criar `.yarnrc.yml` com `nodeLinker: node-modules` (Nuxt tem fricção com o PnP default do Yarn 4). |
| 4 | Binários nativos do Tailwind v4 / Vite | Usar imagem **Debian/glibc** (`node:22-slim`), **não Alpine/musl** — evita falha do `@tailwindcss/oxide` e do Rollup/oxc nativos. |
| 5 | Desacoplamento | `NUXT_PUBLIC_API_BASE` injetada em runtime. Em SSR o servidor Nuxt acessa o backend pela rede interna; o browser, pela URL pública (podem ser URLs distintas). |
| 6 | Tamanho da imagem | Build **multi-stage**: devDependencies só no estágio de build; imagem final apenas com `.output/`. |
| 7 | Segurança | Rodar como usuário **non-root** (uid 1000), espelhando o padrão do backend. |
| 8 | Contexto de build | `.dockerignore` excluindo `node_modules`, `.nuxt`, `.output`, `.yarn/cache`, `.git`. |

### Definições da imagem (`frontend/Dockerfile`)

- **Build multi-stage**: um estágio de build (com devDependencies, gera o
  `.output/`) e um estágio de runtime enxuto (apenas com o `.output/`).
- **Imagem base**: `node:22-slim` (Debian/glibc) nos dois estágios.
- **Gerenciador**: Yarn 4 habilitado via Corepack; instalação de dependências
  em modo imutável (a partir do `yarn.lock`).
- **Build**: gerar o artefato SSR do Nuxt (`.output/`).
- **Runtime**: `NODE_ENV=production`, `HOST=0.0.0.0`, `PORT=3000`; executar o
  servidor SSR a partir do `.output/`.
- **Segurança**: rodar como usuário non-root (uid 1000).
- **Porta exposta**: `3000`.
- Garantir o preset Nitro `node-server` (default do Nuxt ao buildar para Node) e
  fixar a versão do Yarn no campo `packageManager` do `package.json`.

## Entregável
- Projeto Nuxt funcional em `frontend/`, iniciável em desenvolvimento (`yarn dev`).
- Tailwind CSS integrado e validado em ao menos um componente/página de exemplo.
- `Dockerfile` multi-stage + `.dockerignore` no diretório `frontend/`, produzindo
  imagem SSR que sobe o servidor Node.
- Escopo restrito ao **setup**: nenhuma feature de negócio deve ser
  implementada nesta atividade.

## Critérios de aceite
- [ ] `yarn install` executa sem erros no diretório `frontend/`.
- [ ] `yarn dev` sobe a aplicação e ela é acessível no navegador.
- [ ] Uma classe do Tailwind aplicada na página inicial é renderizada corretamente.
- [ ] O gerenciador de pacotes configurado é o Yarn 4.x (via Corepack).
- [ ] `docker build` da imagem do frontend conclui sem erros.
- [ ] O container sobe com `docker run -p 3000:3000` e responde no navegador (SSR).
- [ ] A URL da API é configurável via `NUXT_PUBLIC_API_BASE` (env em runtime).
