# 007 - Compose da raiz + Taskfile (atalhos para o ambiente de desenvolvimento)

## Contexto
O backend do **Paredão BBB 26.5** (Rails 8.1 API-only, PostgreSQL, Redis) já é
orquestrado em desenvolvimento por um `compose.yaml` próprio (ver
[006-backend-compose](./006-backend-compose.md)). Falta, porém, uma orquestração
**do projeto inteiro** — backend **e** frontend juntos — e os comandos de Docker
Compose e de preparação do banco são verbosos e fáceis de errar (nomes de serviço,
flags, ordem de execução).

Esta atividade entrega duas peças complementares:
1. Um **`compose.yaml` na raiz** do projeto que sobe todo o stack de
   desenvolvimento (backend + dependências + frontend).
2. Um **`Taskfile.yaml`** (usando o [go-task](https://taskfile.dev)) que centraliza
   os comandos desse compose em atalhos curtos e memorizáveis, padronizando o fluxo
   de desenvolvimento entre máquinas.

## Objetivo
Criar um **`compose.yaml` na raiz** que orquestre backend e frontend em
desenvolvimento, e um **`Taskfile.yaml`** que envolva os comandos de Docker Compose
e do Rails, oferecendo tasks de ciclo de vida (subir, preparar, buildar, testar,
logar, derrubar) executáveis via `task <nome>`.

## Compose da raiz
- Criar um **`compose.yaml` na raiz do projeto**, espelhando-se no
  `backend/compose.yaml` (task 006): reaproveitar os serviços `app`, `db`
  (`postgres:18`) e `redis` (`redis:8`), com os mesmos healthchecks, volumes
  nomeados, rede interna e configuração por `.env`/`.env.example`.
- Adicionar o serviço **`frontend`** (Nuxt 4 SSR — ver
  [001-setup-frontend](./001-setup-frontend.md)):
  - Buildar a partir do contexto `frontend/` (imagem de desenvolvimento).
  - Mapear a porta do Nuxt para o host (ex.: `3001:3000`, evitando conflito com a
    API em `3000`).
  - Injetar a URL da API em runtime via **`NUXT_PUBLIC_API_BASE`** apontando para o
    serviço `app` pela rede interna do Compose (nunca hardcoded).
  - **Depender** do `app` via `depends_on`.
  - Montar o código-fonte como volume para hot-reload, preservando `node_modules`
    do container.
- É o `compose.yaml` da **raiz** que o `Taskfile.yaml` deve orquestrar (não o de
  `backend/`). O `backend/compose.yaml` permanece válido para trabalhar o backend
  isoladamente.

## Tasks

| Task | Descrição |
|------|-----------|
| `up` | Sobe **todas** as aplicações do ambiente (backend + `db` + `redis` + frontend) a partir do `compose.yaml` da raiz. O serviço da API (`app`) deve subir apenas com o container em espera (ex.: `tail -f /dev/null`), **sem** iniciar o servidor Rails — o boot da API fica a cargo da task `api:up`. |
| `api:up` | Inicia o servidor da API dentro do container já em execução (`bin/rails server` / `bin/dev`). |
| `setup` | Prepara o banco no backend: criação do banco, execução das migrações e do `seeds.rb` (ex.: `bin/rails db:prepare db:seed`). |
| `rspec` | Roda a suíte de testes (RSpec) dentro do container `app`. Aceita argumentos repassados via `--` (ex.: `task rspec -- spec/models/vote_spec.rb:42`). Depende de `up` (o ambiente precisa estar no ar). |
| `build` | Constrói as imagens Docker dos serviços. |
| `logs` | Exibe (e acompanha) os logs dos serviços. |
| `down` | Para e remove todos os serviços. |

## Requisitos

1. **Arquivo `Taskfile.yaml` na raiz.** Usar a sintaxe do go-task (`version: '3'`).
   As tasks devem operar sobre o `compose.yaml` **da raiz** do projeto (o que inclui
   backend e frontend).

2. **`up` não inicia o servidor Rails.** O serviço `app` sobe apenas com o
   container ativo (ex.: `tail -f /dev/null`), permitindo `task api:up` depois. Essa
   separação evita reiniciar todo o ambiente a cada reload da API e facilita anexar
   logs/debug ao processo do servidor.

3. **`api:up` depende do ambiente no ar.** Deve assumir os serviços já de pé (via
   `up`) e apenas iniciar o servidor no container `app` (ex.: `docker compose exec
   app bin/dev`). Documentar se declara `deps: [up]` ou exige `up` prévio.

4. **`setup` idempotente.** Rodar `setup` mais de uma vez não deve quebrar
   (`db:prepare` cria/migra sem erro se o banco já existir). O seed deve ser seguro
   para reexecução.

5. **Task `rspec` com argumentos e dependência de `up`.**
   - Deve repassar os argumentos recebidos após `--` para o comando (ex.:
     `task rspec -- spec/models/vote_spec.rb:42` → `bundle exec rspec
     spec/models/vote_spec.rb:42`), usando `{{.CLI_ARGS}}` do go-task.
   - Sem argumentos (`task rspec`), roda a suíte completa.
   - Executa dentro do container `app` (ex.: `docker compose exec app bundle exec
     rspec {{.CLI_ARGS}}`) e **depende de `up`** (`deps: [up]`), garantindo o
     ambiente no ar antes de testar.
   - Observação: o RSpec ainda não está instalado no backend (ver `CLAUDE.md`);
     a primeira execução pressupõe `bin/rails generate rspec:install` já feito.

6. **Reuso e clareza.** Evitar repetição do comando base do Compose (usar `vars`
   para `docker compose -f ...`). Cada task deve ter `desc:` para aparecer em
   `task --list`.

## Definições
- **go-task** — task runner declarativo em YAML (`Taskfile.yaml`); tasks são
  executadas com `task <nome>` e listadas com `task --list`.
- **Compose da raiz** — `compose.yaml` na raiz do projeto que orquestra o stack
  completo de desenvolvimento (`app`, `db`, `redis`, `frontend`).
- **Ambiente de desenvolvimento** — os serviços definidos no `compose.yaml` da raiz.

## Entregável
- `compose.yaml` na raiz do projeto, espelhado no `backend/compose.yaml` (task 006)
  e acrescido do serviço `frontend` (Nuxt 4 SSR).
- Ajuste no `.env.example` da raiz (se necessário) com as variáveis do frontend
  (ex.: `NUXT_PUBLIC_API_BASE`).
- `Taskfile.yaml` (na raiz) com as tasks `up`, `api:up`, `setup`, `rspec`, `build`,
  `logs` e `down`, operando sobre o compose da raiz.
- Nota no README/documentação sobre a dependência do [go-task](https://taskfile.dev)
  e o fluxo esperado (`task up` → `task setup` → `task api:up`).

## Critérios de aceite
- [ ] Existe um `compose.yaml` na raiz que sobe `app`, `db`, `redis` e `frontend`.
- [ ] O `frontend` responde no host e alcança a API via `NUXT_PUBLIC_API_BASE`.
- [ ] `task --list` exibe todas as tasks com suas descrições.
- [ ] `task up` sobe o ambiente (backend + frontend) com o serviço `app` em espera (sem servidor Rails).
- [ ] `task api:up` inicia a API e ela responde no host (ex.: `GET /up` retorna 200).
- [ ] `task setup` cria o banco, roda as migrações e o seed; reexecutar não quebra.
- [ ] `task rspec` sobe o ambiente (via `up`) e roda a suíte completa.
- [ ] `task rspec -- <path>` repassa o argumento e roda apenas o(s) spec(s) indicado(s).
- [ ] `task build` constrói as imagens sem erros.
- [ ] `task logs` exibe os logs dos serviços.
- [ ] `task down` para e remove todos os serviços.
