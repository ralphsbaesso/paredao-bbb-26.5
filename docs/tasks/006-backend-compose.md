# 006 - Docker Compose do backend (ambiente de desenvolvimento)

## Contexto
O backend do **Paredão BBB 26.5** é uma aplicação **Rails 8.1 API-only**
(`backend/`), que persiste em **PostgreSQL** e é projetada para alto volume de
escrita (meta de ~1000 votos/segundo no pico). Hoje o backend já possui
`Dockerfile` voltado a **produção** (Kamal + Thruster, usuário non-root uid 1000),
mas **não há orquestração para desenvolvimento local**: cada dependência precisa
ser subida manualmente.

O objetivo desta atividade é entregar um **`compose.yaml`** que suba o backend e
suas dependências com um único comando, padronizando o ambiente de
desenvolvimento entre máquinas.

## Objetivo
Criar um **`compose.yaml`** (na raiz de `backend/`) que orquestre o ambiente de
**desenvolvimento** do backend, subindo a aplicação Rails e suas dependências de
infraestrutura de forma reproduzível, com persistência de dados entre reinícios.

## Serviços

| Serviço | Imagem/base | Papel |
|---------|-------------|-------|
| `app` | build a partir do `backend/` (Rails 8.1, Ruby 4.0.5) | API Rails; expõe a porta HTTP para o host |
| `db` | `postgres:18` (última estável da major 18) | Banco de dados primário do backend |
| `redis` | `redis:8` (última estável da major 8) | Cache / suporte a rate-limiting (ver observação acima) |

## Requisitos

1. **Arquivo `compose.yaml` em `backend/`.** Usar a sintaxe atual do Compose
   (sem a chave `version:`, obsoleta). Comando de subida esperado:
   `docker compose up`.

2. **Serviço `app` (Rails).**
   - Buildar a partir do contexto `backend/`. Para desenvolvimento, **não**
     reutilizar o estágio de produção do `Dockerfile` atual (que roda em
     `RAILS_ENV=production` via Thruster) — usar um alvo/imagem de
     desenvolvimento (Ruby 4.0.5, `RAILS_ENV=development`).
   - Mapear a porta do Rails para o host (ex.: `3000:3000`).
   - Injetar a conexão com o banco via **`DATABASE_URL`** (ou variáveis
     equivalentes) apontando para o serviço `db` pela rede interna do Compose.
   - Injetar a URL do Redis via env (ex.: `REDIS_URL`) apontando para o serviço
     `redis`.
   - **Depender** de `db` e `redis` com `depends_on` usando `condition:
     service_healthy` (aguardar os healthchecks, não apenas o container subir).
   - Montar o código-fonte como **volume** para hot-reload em desenvolvimento,
     sem sobrescrever artefatos do container (ex.: preservar `node_modules`/gems
     conforme necessário).

3. **Serviço `db` (PostgreSQL 18).**
   - Imagem oficial `postgres:18`.
   - Configurar credenciais/banco via env (`POSTGRES_USER`, `POSTGRES_PASSWORD`,
     `POSTGRES_DB`) coerentes com o que o `app` espera (`backend_development`).
   - **Volume nomeado** para persistir os dados entre reinícios.
   - **Healthcheck** com `pg_isready`.

4. **Serviço `redis` (Redis 8).**
   - Imagem oficial `redis:8`.
   - **Volume nomeado** para persistência (se persistência for desejada) e
     **healthcheck** com `redis-cli ping`.

5. **Configuração por variáveis de ambiente.** Nenhum segredo hardcoded no
   `compose.yaml`. Usar um arquivo `.env` (com um `.env.example` versionado) ou
   defaults explícitos de desenvolvimento. Não commitar segredos reais.

6. **Rede e isolamento.** Os serviços comunicam-se pela rede interna do Compose
   (referenciados pelo nome do serviço, ex.: `db`, `redis`). Apenas as portas
   necessárias são expostas ao host.

7. **Preparação do banco.** O fluxo de subida deve deixar o banco pronto — via
   `bin/rails db:prepare` no boot do `app` (entrypoint) **ou** documentando o
   comando a rodar após o `up`. Explicitar qual abordagem foi adotada.

## Definições
- **`compose.yaml`** — arquivo de orquestração dos serviços de desenvolvimento do
  backend, na raiz de `backend/`.
- **Volume nomeado** — volume gerenciado pelo Docker que preserva os dados do
  serviço entre `down`/`up`.
- **Healthcheck** — verificação de prontidão do serviço usada por outros serviços
  via `depends_on: condition: service_healthy`.

## Entregável
- `backend/compose.yaml` com os serviços `app`, `db` (`postgres:18`) e `redis`
  (`redis:8`), redes e volumes nomeados.
- `.env.example` (e, se necessário, ajuste no `.dockerignore`/`.gitignore`) com as
  variáveis de ambiente esperadas.
- Alvo/imagem de desenvolvimento para o `app` (não reutilizar o build de produção
  Thruster), com preparação do banco documentada.

## Critérios de aceite
- [ ] `docker compose up` (a partir de `backend/`) sobe os três serviços sem erros.
- [ ] O `app` Rails responde no host (ex.: `GET /up` retorna 200).
- [ ] O `app` conecta ao `db` e ao `redis` pela rede interna do Compose.
- [ ] `db` usa `postgres:18` e `redis` usa `redis:8`.
- [ ] Os dados do PostgreSQL persistem após `docker compose down && docker compose up`
      (volume nomeado).
- [ ] `db` e `redis` possuem healthcheck e o `app` só inicia após ambos estarem
      saudáveis (`depends_on: condition: service_healthy`).
- [ ] Nenhum segredo está hardcoded; as variáveis vêm de `.env` / `.env.example`.
- [ ] O `compose.yaml` não usa a chave obsoleta `version:`.
