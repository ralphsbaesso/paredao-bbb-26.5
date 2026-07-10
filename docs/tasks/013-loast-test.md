# 013 — Teste de carga do `POST /votes` (k6)

## Contexto
O desafio (`docs/desafio-tecnico-fullstack.md`, linha 22) define a meta de pico em
**~1000 votos/segundo** e lista **"Testes de carga / performance"** como diferencial.
Até aqui não havia nenhuma ferramenta de carga no repositório. O README já define o
**SLO** do sistema: *99% dos `POST /votes` respondidos sem 5xx em menos de 500 ms, em
janela deslizante de 30 min* — este é o critério natural de pass/fail do teste.

A stack de observabilidade já está pronta (Yabeda em `/metrics`, Prometheus com scrape
de 5s, Grafana com dashboards de saúde/negócio/SLO), então falta apenas **gerar a carga
e medir**.

Esta atividade entrega um **teste de carga local** contra `POST /votes`, executável via
Docker, sem depender de instalação do k6 na máquina nem de infra de produção.

## Objetivo
Martelar `POST /votes` com carga configurável — de um smoke test leve até o cenário-alvo
de **~1000 req/s** — validando o resultado contra o SLO por meio dos `thresholds` do k6.

## Ferramenta
**k6** (Grafana Labs). Escolhido por: CLI/Docker sem instalação, script em JavaScript,
executor de *arrival-rate* para fixar req/s, e `thresholds` que mapeiam direto no SLO
(fazendo o processo sair com código ≠ 0 quando violado — útil para CI futuro). Por ser da
Grafana Labs, permite (fase futura) *remote-write* das métricas para o Prometheus já
provisionado, exibindo carga + métricas da app lado a lado no Grafana.

## Escopo
- Alvo único: `POST /votes` → `VotesController#create` → `AddVote.call`.
- Body JSON **plano** (atenção à grafia do backend): `{ event_id, partcipant_id, email }`.
- Cada requisição envia o header **`load-test: True`** (contrato da task 012: ignora o
  rate limiting). Hoje o limiter/bypass ainda **não** estão implementados, então a rota é
  irrestrita — mas o header já vai para o teste seguir válido quando a task 012 entrar.
- Cenário secundário leve de leitura (`GET /events/:id/report`) é **opcional** e fica de
  fora desta fase.

## Entregável
- **`load-test/votes.js`** — script k6 autossuficiente:
  - `setup()` chama `GET /events`, prefere um evento **aberto** (`closed_at` nulo) e
    descobre `event_id` + os `partcipant_id` a partir do array `partcipants` da
    serialização (sempre presente, mesmo com 0 votos). Falha cedo, com mensagem clara, se
    o app não estiver no ar/semeado. Aceita override por env `EVENT_ID` / `PARTICIPANT_IDS`.
  - Por iteração: escolhe um participante aleatório, gera email válido único
    (`voter_${__VU}_${__ITER}@loadtest.bbb`) e faz o `POST /votes` com o header de carga.
  - **Checks**: `status === 201` e corpo `status === 'ok'`.
  - **Cenários** (env `SCENARIO`): `smoke` (default — `constant-vus`, 5 VUs, 30s) e
    `ramp_to_1k` (`ramping-arrival-rate` em degraus até 1000 req/s).
  - **Thresholds** (mapeiam o SLO): `http_req_duration p(95)<500` e `p(99)<500`,
    `http_req_failed rate<0.01`, `checks rate>0.99`.
  - `BASE_URL` por env (default `http://localhost:3000`).
- **Task `load-test`** no `Taskfile.yaml` — envelopa o `docker run grafana/k6`,
  aceitando `SCENARIO` e `BASE_URL` como variáveis.

## Como rodar
Pré-requisito: o app no ar em `BASE_URL` com `db:seed` aplicado (um evento aberto com
≥2 participantes). No fluxo do projeto: `task up` → `task setup` → `task api:up`.

Via Taskfile (recomendado):
```bash
task load-test                      # cenario smoke (default)
task load-test SCENARIO=ramp_to_1k  # cenario-alvo (~1000 req/s)
```

Equivalente em Docker puro (a partir da raiz do repo):
```bash
docker run --rm -i --network host \
  -e BASE_URL=http://localhost:3000 \
  -e SCENARIO=smoke \
  -v "$PWD/load-test:/scripts" \
  grafana/k6 run /scripts/votes.js
```

## Expectativa realista (análise para o desafio)
O serviço `app` roda com **um único worker Puma** e `RAILS_MAX_THREADS=5` (sem
`WEB_CONCURRENCY`). É **esperado** que 1000 req/s sustentado estoure o SLO nesse setup —
e o valor do teste é justamente **revelar o teto de capacidade**. Registrar o número
alcançado e as alavancas de melhoria (subir `WEB_CONCURRENCY`/réplicas do `app`, ampliar o
pool do Postgres, tornar os contadores assíncronos) como próximos passos.

## Critérios de aceite
- [ ] `task load-test` roda o k6 via Docker contra `POST /votes` sem exigir k6 instalado.
- [ ] O `setup()` descobre `event_id` + participantes automaticamente e falha com mensagem
      clara quando não há evento semeado.
- [ ] Toda requisição envia body `{ event_id, partcipant_id, email }` e o header
      `load-test: True`.
- [ ] O cenário `smoke` passa (checks ~100%) e o relatório (`GET /events/:id/report`)
      reflete os votos inseridos.
- [ ] O cenário `ramp_to_1k` executa até ~1000 req/s e o resumo do k6 reporta req/s,
      p95/p99 e `http_req_failed`, com os `thresholds` avaliados (pass/fail) contra o SLO.

## Fora de escopo (fases futuras)
- Serviço `k6` no `compose.yaml` (profile `load-test`) e *remote-write* das métricas do k6
  para o Prometheus/Grafana.
- Implementar o rate limiter / bypass `load-test` (task 012).
- Rodar contra produção/EC2 (task 912, ainda só spec).
