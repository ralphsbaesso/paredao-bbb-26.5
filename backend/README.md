# Backend — Paredão BBB 26.5

API REST do sistema de votação do paredão, em **Rails 8.1 API-only** (`config.api_only = true`).
Serviço desacoplado: só se comunica com o frontend via HTTP. É aqui que os votos
são contabilizados, os paredões (eventos) e participantes são administrados e os
relatórios são expostos.

## Stack

- **Ruby 4.0.5** + **Rails 8.1** (API-only), servidor **Puma**.
- **PostgreSQL 18** — banco principal.
- **Redis 8** — usado **apenas** pelo rate limiter de votos (`VoteRateLimiter`).
- Solid Queue / Solid Cache / Solid Cable (jobs, cache e Action Cable no banco).
- Observabilidade: métricas Yabeda em `/metrics` (Prometheus) e logs estruturados em JSON.

## Como rodar (via go-task, a partir da raiz)

O fluxo recomendado sobe o **stack inteiro** (API + Postgres + Redis + frontend +
monitoramento). As tasks vivem no `Taskfile.yaml` **da raiz** do repositório e são
executadas **de lá** (não de `backend/`). Requer [go-task](https://taskfile.dev)
e Docker.

```bash
cp .env.example .env   # ajuste se necessário
task up                # sobe app (API Rails) + db + redis + frontend + monitoramento
task setup             # cria, migra e roda o seed do banco (idempotente)
```

Com isso a API fica em `http://localhost:3000`. Outras tasks:

```bash
task rspec -- spec/models/vote_spec.rb:42   # roda o RSpec no container (args após --)
task build                                   # constrói as imagens dos serviços
task logs                                    # acompanha os logs de todos os serviços
task down                                    # para e remove os serviços
```

## Sem o Taskfile? Use Docker direto

Cada task é um atalho para um `docker compose -f compose.yaml ...` sobre o
`compose.yaml` **da raiz**. Sem o go-task instalado, rode o equivalente **a partir
da raiz do repositório**:

| Task | Comando Docker equivalente (da raiz) |
| --- | --- |
| `task up` | `docker compose -f compose.yaml up -d` |
| `task setup` | `docker compose -f compose.yaml exec app bin/rails db:prepare db:seed` |
| `task rspec -- ARGS` | `docker compose -f compose.yaml exec app bundle exec rspec ARGS` |
| `task build` | `docker compose -f compose.yaml build` |
| `task logs` | `docker compose -f compose.yaml logs -f` |
| `task down` | `docker compose -f compose.yaml down` |

Exemplo, reproduzindo `task up` + `task setup`:

```bash
docker compose -f compose.yaml up -d
docker compose -f compose.yaml exec app bin/rails db:prepare db:seed
```

## Portas e endpoints

Com o stack no ar:

- API: `http://localhost:3000`
  - `GET /up` — health check
  - `/api-docs` — Swagger UI (Rswag)
  - `/metrics` — métricas Prometheus (Yabeda)
- Frontend: `http://localhost:3001`
- Grafana: `http://localhost:3002` &nbsp;·&nbsp; Prometheus: `http://localhost:9090`

## Backend isolado (opcional)

Para trabalhar só o backend, sem o stack da raiz, você pode rodar direto na sua
máquina (Ruby 4.0.5 + PostgreSQL):

```bash
bin/setup              # instala gems, prepara o banco e sobe o servidor
bin/dev                # sobe o servidor
bin/rails console      # REPL
bundle exec rspec      # roda a suíte de testes (ou um arquivo: spec/path_spec.rb:42)
```

Também há um `backend/compose.yaml` para subir Postgres + Redis + um container do
app isolado — observe que, nele, o container `app` sobe ocioso e **não serve a API
sozinho**; para o fluxo completo prefira o `compose.yaml` da raiz.
