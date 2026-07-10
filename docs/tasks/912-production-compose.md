# 012 — Docker Compose de produção (EC2)

## Contexto

Hoje o projeto tem **um único orquestrador**, o `compose.yaml` da raiz, voltado a
**desenvolvimento**: builda `app` e `frontend` a partir dos `Dockerfile.dev`,
faz **bind-mount** do código para hot-reload, roda o Rails em
`RAILS_ENV=development` e **publica no host** as portas de todos os serviços
(API em 3000, frontend em 3001, Grafana em 3002, Prometheus em 9090). Isso é
ótimo na máquina do dev e **impróprio para produção**: expõe serviços internos
direto na internet, não termina TLS, não usa os artefatos de produção e depende
do código-fonte montado do host.

As imagens de produção **já existem** e não devem ser recriadas aqui:
- `backend/Dockerfile` — multi-stage, `RAILS_ENV=production`, non-root uid 1000,
  sobe via **Thruster** (`bin/thrust ./bin/rails server`) escutando na **porta 80**.
- `frontend/Dockerfile` — multi-stage SSR, `NODE_ENV=production`, usuário `node`
  (uid 1000), sobe `node .output/server/index.mjs` na **porta 3000**.

O alvo de deploy é **uma instância EC2** rodando Docker + Docker Compose. O
acesso externo deve entrar por um **único ponto** (um serviço `nginx`), que faz
proxy reverso para o frontend e a API. Os demais serviços ficam **apenas na rede
interna** do Compose, sem portas publicadas.

> **Esta atividade é só de especificação.** Descreve o `compose` de produção e o
> que ele exige; não implementa. A implementação (arquivos + deploy) vem depois.

## Objetivo

Entregar um **`compose.prod.yaml`** (na raiz) que suba, numa EC2, **todos os
serviços do `compose.yaml` atual** — `app`, `db`, `redis`, `frontend`,
`prometheus`, `grafana` — em modo **produção**, **mais** um serviço **`nginx`**
como porta de entrada única para o mundo externo. Nenhum serviço além do `nginx`
publica portas no host.

## Serviços

| Serviço | Imagem/origem | Papel | Porta publicada no host |
|---------|---------------|-------|-------------------------|
| `nginx` | `nginx:1.27` (ou estável equivalente) | Proxy reverso / TLS / único ingresso externo | **80 e 443** |
| `frontend` | build `frontend/Dockerfile` (**estágio runtime**, SSR) | UI Nuxt 4 SSR | nenhuma (só rede interna, `:3000`) |
| `app` | build `backend/Dockerfile` (produção, Thruster) | API Rails 8.1 | nenhuma (só rede interna, `:80`) |
| `db` | `postgres:18` | Banco primário (produção) | nenhuma |
| `redis` | `redis:8` | Cache / suporte a rate-limiting | nenhuma |
| `prometheus` | `prom/prometheus:v3.1.0` | Coleta de métricas (`app/metrics`) | nenhuma (via `nginx`, ver §Observabilidade) |
| `grafana` | `grafana/grafana:11.4.0` | Dashboards (SLO/SLI, negócio, saúde) | nenhuma (via `nginx`) |

## Requisitos

### 1. Arquivo e invocação
- **`compose.prod.yaml` na raiz** (não sobrescrever o `compose.yaml` de dev, que
  segue válido). Sintaxe atual do Compose (sem a chave obsoleta `version:`).
- Subida esperada na EC2: `docker compose -f compose.prod.yaml up -d`.
- Todos os serviços com **`restart: unless-stopped`** (sobrevivem a reboot da
  instância e a crashes).
- Considerar um atalho no `Taskfile.yaml` (ex.: `task prod:up` / `task prod:down`),
  coerente com a task 007.

### 2. Imagens de produção (nada de dev)
- `app` builda o **estágio final** do `backend/Dockerfile` (Thruster, porta 80),
  **não** o `Dockerfile.dev`. `RAILS_ENV=production`.
- `frontend` builda o **estágio `runtime`** do `frontend/Dockerfile` (SSR, porta
  3000), **não** o `Dockerfile.dev`.
- **Sem bind-mount de código** e **sem `command:` de dev**: rodam os artefatos
  buildados (`.output/` no frontend; gems + código copiados no backend). Volumes
  só para **dados persistentes** (Postgres, Redis) e o que o Rails precisa em
  runtime (ex.: `tmp/`), nunca o código do host.

### 3. `nginx` — ingresso único e proxy reverso
- Único serviço com portas publicadas: **80** e **443**.
- Config versionada em `infra/nginx/` (ex.: `nginx.conf` + `conf.d/`), montada
  read-only no container.
- Roteamento (a definir o esquema exato — ver questões em aberto), tipicamente
  **por caminho** sob um só domínio:
  - `/api/…` (e/ou `/up`, `/admin`, `/votes`, `/metrics` conforme o contrato) →
    `proxy_pass` para `app:80`.
  - `/` (todo o resto) → `proxy_pass` para `frontend:3000` (SSR).
  - Alternativa: **subdomínios** (`api.dominio`, `app.dominio`) — decidir na
    implementação.
- **TLS**: 443 com certificado (Let's Encrypt/ACME ou certificado fornecido).
  Redirecionar 80 → 443. Onde e como os certificados são obtidos/renovados deve
  ser documentado (ex.: volume de certs + companion ACME, ou terminação no ALB —
  ver questões em aberto).
- Repassar headers corretos ao upstream (`Host`, `X-Forwarded-For`,
  `X-Forwarded-Proto`) para que Rails e Nuxt saibam o host/esquema público.
- Ajustar limites coerentes com a meta de escrita (~1000 votos/s): `keepalive`
  para os upstreams, `client_max_body_size` adequado, timeouts.

### 4. Rede e exposição
- Uma rede interna do Compose; serviços referenciados pelo **nome**
  (`app`, `frontend`, `db`, `redis`, `prometheus`, `grafana`).
- **Somente `nginx`** mapeia portas para o host. `app`, `frontend`, `db`,
  `redis`, `prometheus` e `grafana` **não** publicam portas (diferente do compose
  de dev). Na EC2, o **security group** libera apenas 80/443 (e 22 p/ SSH).

### 5. Backend em produção (`app`)
- `RAILS_ENV=production` e `DATABASE_URL` apontando para o serviço `db`
  (banco/credenciais de **produção**, não `backend_development`).
- `REDIS_URL` apontando para `redis`.
- **Segredos** injetados por ambiente, nunca hardcoded: `RAILS_MASTER_KEY`
  (ou `SECRET_KEY_BASE`) e as credenciais do banco vêm do `.env` de produção
  (fora do versionamento).
- Preparação do banco no boot: o `docker-entrypoint` do backend já roda
  `db:prepare`; confirmar que migra/prepara em produção antes de servir.
- **CORS**: o backend deve liberar a **origem pública** servida pelo `nginx`
  (o mesmo domínio, se o roteamento for por caminho), incluindo o header
  `Authorization`.

### 6. Frontend em produção (`frontend`)
- `NUXT_PUBLIC_API_BASE` = **URL pública** da API (o domínio HTTPS servido pelo
  `nginx`, ex.: `https://dominio/api`) — usada pelo **browser**.
- `NUXT_API_BASE_INTERNAL` = `http://app:80` (rede interna do Compose) — usada
  no **SSR**. As duas bases são distintas, como no dev.
- Injetadas em **runtime** (nunca no build), coerente com a task 001.

### 7. `db` e `redis`
- `postgres:18` e `redis:8`, cada um com **volume nomeado** para persistência e
  **healthcheck** (`pg_isready` / `redis-cli ping`).
- `app` depende de ambos com `depends_on: condition: service_healthy`.

### 8. Observabilidade (`prometheus` + `grafana`)
- Reaproveitar as configs já versionadas em `infra/monitoring/` (Prometheus
  scrape de `app:80/metrics`; Grafana provisionado por código — datasource + 3
  dashboards). **Nada criado só pela UI.**
- **Não** publicar portas: o acesso externo ao Grafana (e, se desejado, ao
  Prometheus) passa pelo `nginx` (ex.: `/grafana/` com `proxy_pass` para
  `grafana:3000`), **protegido** — no mínimo com as credenciais de admin vindas
  do `.env` de produção (nada de `admin/admin`).
- Ajustar `GF_SERVER_ROOT_URL` / subpath do Grafana se ele for servido sob um
  caminho pelo `nginx`.

### 9. Configuração por variáveis de ambiente
- Nenhum segredo no `compose.prod.yaml`. Variáveis vêm de um **`.env` de
  produção** na EC2 (não versionado), com um **`.env.production.example`**
  versionado documentando as chaves esperadas (sem valores reais):
  credenciais do Postgres de produção, `RAILS_MASTER_KEY`/`SECRET_KEY_BASE`,
  `NUXT_PUBLIC_API_BASE` público, credenciais do Grafana, domínio/paths do
  `nginx`.

## Entregável
- `compose.prod.yaml` na raiz, subindo `nginx`, `frontend`, `app`, `db`, `redis`,
  `prometheus` e `grafana` em modo produção, com rede e volumes nomeados,
  `restart: unless-stopped` e **apenas o `nginx` publicando portas (80/443)**.
- Config do `nginx` versionada em `infra/nginx/` (proxy reverso + TLS + roteamento
  frontend/API/Grafana).
- `.env.production.example` versionado com as chaves esperadas (sem segredos).
- Atalhos de subida/derrubada documentados (README e/ou `Taskfile.yaml`), com o
  passo a passo de deploy na EC2 (pré-requisitos: Docker/Compose, security group
  80/443/22, provisão de segredos e certificados).

## Fora de escopo
- Provisionamento da própria EC2 e da rede (IaC/Terraform) — o `infra/` guarda
  configs, mas a criação da instância é atividade à parte.
- Pipeline de CI/CD que builda e publica as imagens e dispara o deploy.
- Escalonamento horizontal (múltiplas réplicas do `app`, load balancer gerenciado,
  RDS/ElastiCache) — aqui é single-node Compose numa EC2.
- Alterações nas imagens de produção (`backend/Dockerfile`, `frontend/Dockerfile`)
  ou no código de aplicação.

## Questões em aberto
- **Roteamento do `nginx`**: por **caminho** sob um domínio (`/` → frontend,
  `/api` → app) ou por **subdomínio** (`app.` / `api.`)? Impacta `NUXT_PUBLIC_API_BASE`,
  o CORS e o prefixo das rotas Rails.
- **TLS**: terminar no `nginx` do Compose (Let's Encrypt/ACME + volume de certs)
  ou num **ALB/CloudFront** à frente da EC2 (o `nginx` só faz HTTP interno)?
- **Prometheus exposto?**: Grafana é o ponto de consumo; expor o Prometheus via
  `nginx` (protegido) é opcional — decidir.
- **Persistência de métricas**: retenção do TSDB do Prometheus e do estado do
  Grafana na EC2 (tamanho dos volumes / disco da instância).

## Critérios de aceite
- [ ] `docker compose -f compose.prod.yaml up -d` sobe todos os serviços na EC2 sem erros.
- [ ] `app` e `frontend` rodam a partir das **imagens de produção** (Thruster / SSR),
      sem bind-mount de código nem `RAILS_ENV=development`.
- [ ] **Apenas** o `nginx` publica portas no host (80 e 443); nenhum outro serviço
      expõe porta.
- [ ] O site responde por HTTPS no domínio público; 80 redireciona para 443.
- [ ] O browser carrega o frontend SSR e as chamadas à API passam pelo `nginx`
      até o `app` (CORS e `NUXT_PUBLIC_API_BASE` coerentes com o domínio público).
- [ ] O SSR do Nuxt alcança a API pela rede interna (`app:80`).
- [ ] `db` e `redis` têm volume nomeado + healthcheck; o `app` só inicia após ambos
      saudáveis, e os dados persistem após `down`/`up`.
- [ ] Grafana acessível (protegido) via `nginx`, com datasource e dashboards
      provisionados por código; Prometheus faz scrape de `app:80/metrics`.
- [ ] Nenhum segredo hardcoded: tudo vem do `.env` de produção; há
      `.env.production.example` versionado.
- [ ] `compose.prod.yaml` não usa a chave obsoleta `version:` e todos os serviços
      têm `restart: unless-stopped`.
