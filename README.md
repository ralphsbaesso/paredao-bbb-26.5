# paredao-bbb-26.5

Sistema de votação do "paredão" do BBB. Monorepo com serviços independentes e
desacoplados: `backend/` (API Rails 8.1, API-only) e `frontend/` (Nuxt 4 SSR,
planejado). Backend e frontend se comunicam **apenas via HTTP** — a URL da API é
injetada no frontend em runtime através de `NUXT_PUBLIC_API_BASE` (nunca
hardcoded).

A votação do público é **anônima e ilimitada** (não há login de eleitor). A
autenticação descrita abaixo é **exclusiva de administradores**, que operam a
área de gestão (paredões, participantes, relatórios).

## Ambiente de desenvolvimento (Docker Compose + Taskfile)

O `compose.yaml` da raiz orquestra o stack completo — `app` (API Rails),
`db` (PostgreSQL 18), `redis` (Redis 8) e `frontend` (Nuxt 4 SSR). Os comandos
são encapsulados por um [go-task](https://taskfile.dev) (`Taskfile.yaml`),
que **depende do go-task instalado** na máquina. Liste os atalhos com
`task --list`.

Fluxo esperado:

```bash
cp .env.example .env   # ajuste as variáveis se necessário
task up                # sobe todo o ambiente: app (API Rails) + db + redis + frontend
task setup             # cria/migra o banco e roda o seed (idempotente)
```

- **`task up`** sobe todo o ambiente — `app` (API Rails, já com o servidor de pé
  em `http://localhost:3000`, ex.: `GET /up`), `db`, `redis`, `frontend` e a
  stack de monitoramento (Prometheus/Grafana).
- **`task rspec`** sobe o ambiente (via `up`) e roda a suíte no container `app`;
  aceita argumentos após `--` (ex.: `task rspec -- spec/models/vote_spec.rb:42`).
- **`task build`**, **`task logs`** e **`task down`** constroem as imagens,
  acompanham os logs e derrubam o ambiente, respectivamente.

O frontend responde em `http://localhost:3001` e alcança a API pela rede interna
do Compose via `NUXT_PUBLIC_API_BASE` (padrão `http://app:3000`). O
`backend/compose.yaml` continua válido para trabalhar o backend isoladamente.

## Observabilidade (Prometheus + Grafana)

O `compose.yaml` da raiz também sobe a stack de monitoramento (task 009). A API
Rails é instrumentada com [Yabeda](https://github.com/yabeda-rb/yabeda) e expõe
métricas no formato Prometheus.

| Serviço | URL | Credenciais |
| --- | --- | --- |
| Métricas da API | http://localhost:3000/metrics | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3002 | `GRAFANA_USER` / `GRAFANA_PASSWORD` (padrão `admin`/`admin`) |

As portas são configuráveis via `.env` (`PROMETHEUS_PORT`, `GRAFANA_PORT`,
`GRAFANA_USER`, `GRAFANA_PASSWORD`). Toda a configuração é versionada em
`infra/monitoring/` (scrape do Prometheus, data source e dashboards do Grafana —
_provisioning as code_, nada criado só pela UI).

> ℹ️ O Prometheus faz scrape da API em `app:3000/metrics`. Como o `task up` já
> sobe o servidor da API, o alvo aparece _up_ assim que o ambiente termina de
> subir.

**Métricas expostas** (`/metrics`):

- `rails_requests_total` — contador de requisições por `controller`/`action`/`status`.
- `rails_request_duration_seconds` — histograma de latência (para percentis p50/p95/p99).
- `paredao_votes_total` — contador de votos por `event`/`participant` (métrica de negócio).

**Dashboards** (provisionados na pasta _Paredão BBB_ do Grafana):

1. **Saúde da API** — requisições/s, latência (p50/p95/p99) e taxa de erros por rota.
2. **Negócio** — votos/s, votos por minuto e total de votos por participante.
3. **SLO/SLI** — disponibilidade e latência do fluxo de votação, com _error budget_.

**SLO definido:** 99% das requisições de voto (`POST /votes`) respondidas com
sucesso (não-5xx) em menos de 500 ms, em janela deslizante de 30 min. O SLI
correspondente é calculado a partir de `rails_requests_total` /
`rails_request_duration_seconds` e exibido no dashboard SLO/SLI.

**Logs estruturados:** a API emite logs em JSON nos quatro níveis (`debug`,
`info`, `warn`, `error`) — ver `AddVote` e `config/initializers/structured_logging.rb`.
Uma execução com erro é registrada no nível `error` quando o registro do voto
falha de forma inesperada.

## Teste de carga (k6)

A rota pública `POST /votes` tem um teste de carga com [k6](https://k6.io),
executado **via Docker** (não exige o k6 instalado). O script fica em
`load-test/votes.js` e valida o resultado contra o SLO acima através dos
`thresholds` do k6 (`p95<500ms`, `p99<500ms`, `http_req_failed<1%`) — a task 013
(`docs/tasks/013-loast-test.md`) descreve a atividade em detalhe.

**Pré-requisito:** a API precisa estar no ar e com o seed aplicado (um evento
aberto com ≥2 participantes). Rode o fluxo normal antes: `task up` → `task setup`.
O script descobre `event_id` e os participantes automaticamente via `GET /events`.

```bash
task load-test                      # cenário smoke (5 VUs, 30s) — rode este primeiro
task load-test SCENARIO=ramp_to_1k  # cenário-alvo: sobe em degraus até ~1000 req/s
```

Variáveis aceitas: `SCENARIO` (`smoke` padrão | `ramp_to_1k`) e `BASE_URL`
(padrão `http://localhost:3000`). Equivalente em Docker puro, a partir da raiz:

```bash
docker run --rm -i --network host \
  -e BASE_URL=http://localhost:3000 \
  -e SCENARIO=smoke \
  -v "$PWD/load-test:/scripts" \
  grafana/k6 run /scripts/votes.js
```

Cada requisição envia o header `load-test: True` (contrato da task 012) e o
resumo final do k6 reporta req/s, latências (p95/p99) e `http_req_failed`, com os
`thresholds` avaliados como pass/fail.

> ⚠️ Com o `app` em um único worker Puma (`RAILS_MAX_THREADS=5`, sem
> `WEB_CONCURRENCY`), é **esperado** que 1000 req/s sustentado estoure o SLO —
> o teste serve justamente para **revelar o teto de capacidade** do setup atual.

## Autenticação de administradores

O backend é **API-only** (sem views, sem sessão por cookie): a autenticação é
**por token**. O login emite um token de sessão opaco que o cliente reapresenta
no header `Authorization` das requisições seguintes. Todas as respostas são
**JSON** — nenhuma rota de autenticação renderiza HTML nem redireciona para tela
de login.

### Como o frontend autentica

Faz `POST /admin/session` enviando as credenciais em JSON:

```http
POST /admin/session
Content-Type: application/json

{ "email_address": "admin@exemplo.com", "password": "sua-senha" }
```

- **Sucesso** → `201 Created` com o token e sua expiração:

  ```json
  {
    "token": "Fzyb4T6pxUnLza3bFnEa97jh",
    "expires_at": "2026-07-08T01:05:35.021Z",
    "admin_user": { "id": 1, "email_address": "admin@exemplo.com" }
  }
  ```

- **Credenciais inválidas** → `401 Unauthorized` (`{ "error": "invalid_credentials" }`).
- **Excesso de tentativas** → `429 Too Many Requests` (rate limit de 10 tentativas / 3 min).

### Como o frontend armazena e reutiliza a credencial

O frontend guarda o `token` retornado e o envia em **todas** as chamadas
autenticadas no header `Authorization`, no formato `Bearer`:

```http
GET /admin/profile
Authorization: Bearer Fzyb4T6pxUnLza3bFnEa97jh
```

O tempo de vida do token vem de `ADMIN_SESSION_TTL_HOURS` (padrão 24h); use
`expires_at` para saber quando renovar (fazer login novamente).

### Comunicação backend ↔ frontend após autenticado

- **Rotas que exigem token** (administrativas): tudo sob `/admin/*`, exceto o
  login. Ex.: `GET /admin/profile`. Novos endpoints de gestão herdam de
  `Admin::BaseController` e passam a exigir token automaticamente.
- **Rotas públicas** (sem token): votação (a implementar) e o health check
  `GET /up`.
- **Sem credencial, com token inválido ou expirado** → `401 Unauthorized`
  (`{ "error": "unauthorized" }`). O backend **nunca** redireciona para uma tela
  de login. O frontend deve tratar o `401` limpando o token armazenado e
  levando o administrador de volta à tela de login.
- **Logout**: `DELETE /admin/session` (com o header `Authorization`) invalida o
  token no servidor e responde `204 No Content`. O token deixa de ser aceito.

### Provisionamento do primeiro administrador

Não há auto-registro. O administrador inicial é criado por um destes mecanismos,
sempre com credenciais vindas do ambiente (nunca hardcoded):

```bash
# Via rake (recomendado):
bin/rails admin:create EMAIL=admin@exemplo.com PASSWORD=sua-senha

# Via seeds (idempotente); lê ADMIN_EMAIL / ADMIN_PASSWORD:
ADMIN_EMAIL=admin@exemplo.com ADMIN_PASSWORD=sua-senha bin/rails db:seed
```

Em `development`, `db:seed` sem variáveis cria um admin de conveniência
(`admin@paredao.local` / `password123`). Senhas são sempre armazenadas apenas
como hash (`has_secure_password`).

### Configuração / segurança

- **CORS**: habilitado e escopado à origem do frontend via `FRONTEND_ORIGIN`
  (padrão `http://localhost:3000`; aceita lista separada por vírgula).
- **Segredos e expiração** vêm de variáveis de ambiente / credenciais do Rails:
  `ADMIN_SESSION_TTL_HOURS`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `FRONTEND_ORIGIN`.
