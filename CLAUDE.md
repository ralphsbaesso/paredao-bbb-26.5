# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`paredao-bbb-26.5` is a solution to a fullstack technical challenge (`docs/desafio-tecnico-fullstack.md`, in Portuguese): a **BBB "paredão" voting system**. The public votes for one of the contestants via a web UI and sees live percentage results; admins manage paredões (events), contestants, and reports. The full spec (in Portuguese) drives all requirements — read it before making product decisions.

Key domain constraints from the challenge that shape architecture:
- Public voting is **anonymous and unlimited** (no voter login), but the system must resist bot/automated votes.
- Designed for high write throughput — target **~1000 votes/second** at peak. This drives the Redis vote rate limiter and its load-test bypass (see the vote flow below).
- A reporting URL must expose: total votes, totals per contestant, and votes per hour.
- Deliverables emphasize containerization (API and frontend as separate services), load testing, IaC, CI/CD, an SLO/SLI, structured logging (warn/error/debug/info), and real-time metrics dashboards (Prometheus/similar).

## Repository layout

Monorepo with independent, decoupled services (no shared code; communication only via the REST API):
- `backend/` — Rails 8.1 **API-only** app (`config.api_only = true`). The vote-counting REST API.
- `frontend/` — Nuxt 4 SSR app (composables `useApi`/`useVotingData`/`useAuth`, pages `index.vue`/`votacao.vue`, admin layout + `admin-auth` middleware). Talks to the backend only over HTTP; the API base URL is injected at runtime via `NUXT_PUBLIC_API_BASE` (client) and `NUXT_API_BASE_INTERNAL` (SSR) — never hardcoded.
- `infra/` — `infra/monitoring/` holds versioned Prometheus scrape config + Grafana provisioning/dashboards. `infra/nginx/` is planned (task 912, production ingress).
- `docs/` — the challenge spec and per-task specs under `docs/tasks/`.

A root `compose.yaml` + `Taskfile.yaml` (go-task) orchestrate the whole dev stack (`app`, `db`, `redis`, `frontend`, plus Prometheus/Grafana). `backend/compose.yaml` still works for the backend in isolation.

## Current state

Fully implemented, not a scaffold. The backend has domain models, admin + public REST APIs, service objects, and RSpec specs; the frontend is a working SSR app; monitoring (Prometheus/Grafana/Yabeda) is wired up. `docs/tasks/` is the source of truth for scoped work — e.g. `012` (vote rate limiting, implemented), `013` (load test, placeholder/empty), `912` (production compose, spec only). Consult the relevant task file before implementing.

## Commands

**Primary dev flow — full stack via go-task, from the repo root** (requires `docker` + [go-task](https://taskfile.dev); `task --list` shows all):

```bash
cp .env.example .env   # then adjust if needed
task up                # bring up the whole stack: app (Rails API) + db + redis + frontend + monitoring
task setup             # create/migrate/seed the DB (idempotent)
```

`task up` boots the entire environment, including the Rails API in the `app` container (serving at http://localhost:3000). Other tasks:

```bash
task rspec -- spec/path/to/file_spec.rb:42   # run RSpec in the container (args after --)
task build   # build service images
task logs    # tail all service logs
task down    # stop and remove services
```

Frontend serves at `http://localhost:3001`; Grafana `http://localhost:3002`, Prometheus `http://localhost:9090`, API metrics at `:3000/metrics`.

**Backend in isolation** — run from `backend/` (Ruby 4.0.5 per `.tool-versions`/`.ruby-version`, PostgreSQL):

```bash
bin/setup              # install gems, prepare DB, start server (--skip-server to skip)
bin/rails db:prepare   # create + migrate the database
bin/dev                # run the server
bin/rails console      # REPL
bin/ci                 # full local CI suite (see config/ci.rb)
bin/rubocop [-A]       # lint (omakase, single-quote strings); -A autocorrects
bin/brakeman           # static security analysis
bin/bundler-audit      # audit gems for known CVEs
bundle exec rspec [spec/path_spec.rb:42]   # run specs (all / single file / single line)
```

RSpec is installed. Specs live in `backend/spec/` (request specs under `spec/requests/`, service specs under `spec/services/`, FactoryBot factories under `spec/factories/`). `spec/rails_helper.rb` stubs the global `REDIS`, so specs need no live Redis. Note: `config/ci.rb` and `.github/workflows/ci.yml` currently run lint + security scans only — add the spec step if wiring tests into CI.

## Backend architecture notes

- **Rails 8.1, API-only**, PostgreSQL via `pg`, Puma. Loads full Rails defaults 8.1.
- **Solid stack** (`solid_queue`, `solid_cache`, `solid_cable`) backs jobs, cache, and Action Cable (database-backed; separate `primary`/`cache`/`queue`/`cable` DBs — see `config/database.yml`). **Redis** is a separate runtime dependency used **only** for the vote rate limiter (`config/initializers/redis.rb` sets a global `REDIS`; `REDIS_URL` env).
- **Routes** (`config/routes.rb`):
  - `namespace :admin` — `resource :session` (login/logout), `resource :profile`, `resources :events` (+ member `close`), `resources :partcipants`.
  - Public — `resources :events` (+ member `report`), `resources :votes` (create only).
  - `mount Rswag::Ui` at `/api-docs`, `mount Yabeda::Prometheus::Exporter` at `/metrics`, `get 'up'` health check.
- **Vote flow**: `VotesController#create` runs `enforce_rate_limit` before writing. `VoteRateLimiter` (`app/services/vote_rate_limiter.rb`) is a fixed-window Redis limiter (`INCR`+`EXPIRE`, key `vote_rl:<event_id>:<ip>`, default 1 rps via `VOTE_RATE_LIMIT_RPS` / `VOTE_RATE_LIMIT_WINDOW_SECONDS`); it **fails open** (allows the vote, logs) if Redis is down, and returns 429 with `Retry-After` when blocked. A `load-test` request header bypasses the limiter, gated by `ENV['LOAD_TEST_TOKEN']` (or the literal `true` in non-production). The vote itself is created by `AddVote` (`app/services/add_vote.rb`), which validates the email and increments the `paredao_votes_total` metric.
- **Admin auth** is token-based: login returns an opaque session token reused via `Authorization: Bearer`. API-only — never renders HTML or redirects. `Admin::BaseController` enforces the token.
- **Observability**: Yabeda metrics at `/metrics` (`rails_requests_total`, `rails_request_duration_seconds`, `paredao_votes_total`); JSON structured logging (`config/initializers/structured_logging.rb`).
- **CORS** (`config/initializers/cors.rb`) is enabled. The code is currently wide-open `origins '*'` — hardening TODO: scope it to the frontend origin (the README claims `FRONTEND_ORIGIN` scoping; code and README disagree).
- **Deploy** via Kamal (`config/deploy.yml`) + Thruster; `Dockerfile` targets production. `bin/jobs` runs the Solid Queue worker. Databases are `backend_development` / `backend_test` / `backend_production*`.

## Conventions

- Rubocop uses `rubocop-rails-omakase` with **single-quoted strings** enforced and several cops relaxed (see `.rubocop.yml`); match this style.
- **Do not add code comments.** Prefer clear names and small methods. Add a comment only when genuinely necessary to explain *why* something non-obvious is done — not *what* the code does. The codebase is deliberately almost comment-free; match it.
- **`partcipant` is misspelled on purpose** (missing the second "i") and is used consistently across models, tables, routes, controllers, services, specs, and factories. Do not "correct" it — matching the spelling exactly is required for the code to work.
- Task specs in `docs/tasks/` are the source of truth for scoped work — e.g. task 001 (frontend setup) documents hard container requirements (SSR, Yarn 4 via Corepack, `nodeLinker: node-modules`, Debian/glibc base image, non-root uid 1000). Consult the relevant task file before implementing.
