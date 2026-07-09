# 011 — Comunicação frontend ↔ backend

Conectar o frontend Nuxt ao backend Rails de verdade, substituindo os dados
mockados pela API REST. O contrato da API é o `backend/openapi/v1/openapi.yaml`
(fonte da verdade dos endpoints já roteados).

> **Esta atividade é só de especificação.** Descreve o que falta; não altera
> código. A implementação vem depois.

## Estado atual

O frontend está **parcialmente** integrado:

- ✅ **Autenticação** (`app/composables/useAuth.ts`) — já consome de verdade
  `POST /admin/session`, `DELETE /admin/session` e `GET /admin/profile`. Guarda
  o token em cookie, reenvia no header `Authorization: Bearer`, resolve a base
  da API por SSR/browser (`apiUrl`) e o middleware `admin-auth` valida o token
  contra o backend. **Nada a fazer aqui.**
- ❌ **Dados de votação** (`app/composables/useVotingData.ts`) — **100%
  mockado**, em memória (`useState` + semente estática). Todas as telas de
  produto dependem dele:
  - `/votacao` (público): evento aberto + participantes + votações anteriores.
  - `/admin` (index): contagens de eventos/participantes.
  - `/admin/events`: listar/criar/encerrar/visualizar eventos e votos.
  - `/admin/participants`: listar/cadastrar participantes.
  - `components/EventVotes.vue`: placar (votos e % por participante).

O objetivo desta atividade é trocar esse composable mockado por integração HTTP
real, e cobrir as lacunas do backend que essa troca expõe.

## Lacunas identificadas

### A. Endpoints que faltam no backend

O `openapi.yaml` hoje só expõe, além de auth: `POST /admin/events`,
`PATCH /admin/events/{id}/close`, `GET/POST /admin/partcipants`,
`GET /admin/partcipants/{id}`, `POST /votes`. Isso **não é suficiente** para o
frontend. Falta:

1. **Listagem de eventos** — nenhuma rota lista eventos. A tela `/admin/events`
   e o painel `/admin` precisam listar todos os eventos; a tela pública
   `/votacao` precisa do evento aberto e dos encerrados. Não existe
   `GET /admin/events` (index) nem equivalente. **Definir e rotear.**
2. **Detalhe de um evento com participantes + votos** — não existe
   `GET /admin/events/{id}` (show). As telas de "visualizar evento" e o placar
   precisam do evento **com seus participantes e a contagem de votos por
   participante**. O schema `Event` do OpenAPI hoje só tem
   `id/title/closed_at/created_at/updated_at` — **sem participantes e sem
   votos**.
3. **Leitura pública (sem token)** — `/votacao` é área pública e não tem
   credencial de admin. As listagens/detalhes acima precisam de uma variante
   pública **ou** de endpoints públicos dedicados (ex.: `GET /events`,
   `GET /events/{id}`) que devolvam o evento aberto, os encerrados e os placares
   sem exigir `Authorization`. **Decidir a superfície pública** (ver questões em
   aberto).
4. **Placar / apuração** — `POST /votes` devolve só `{ status: "ok" }`. Não há
   como ler os totais. Falta um endpoint de resultados por evento (votos por
   participante + total).
5. **URL de relatório** (requisito do desafio, `docs/desafio-tecnico-fullstack.md`)
   — total de votos, total por participante e **votos por hora**. Não existe
   nenhum endpoint assim. Precisa ser criado e (idealmente) consumido pelo
   frontend.

Todo endpoint novo deve ser **documentado no `openapi.yaml`** (o arquivo é
mantido à mão e é a fonte da verdade).

### B. Divergências de contrato (frontend ↔ API)

O tipo do frontend e o schema da API **não batem**. Ao integrar, mapear:

| Domínio | Frontend (`useVotingData`) | API (`openapi.yaml`) |
|---|---|---|
| id | `string` (`'p1'`, `'e1'`) | `integer` |
| Participante — nome | `name` | `nickname` |
| Participante — extra | (não tem) | `eliminated: boolean` |
| Evento — nome | `name` | `title` |
| Evento — situação | `status: 'open' \| 'closed'` (derivado) | só `closed_at` (nulo = aberto) |
| Datas | `createdAt` / `closedAt` (camelCase) | `created_at` / `closed_at` (snake_case) |
| Evento — participantes | `participants[]` embutido | **ausente** no schema `Event` |
| Evento — votos | `votes: Record<id, number>` | **ausente** |

Além disso, atenção ao **typo proposital** do backend: os campos são
`partcipant_id` e `partcipant_ids` (sem o segundo "i"). O frontend usa
`participant`/`participantId` internamente — o mapeamento precisa traduzir os
nomes na borda HTTP.

> O vocabulário de **avatares** já está alinhado: os 30 nomes de
> `app/utils/avatars.ts` (`AVATAR_VARIANTS`) são exatamente o `enum` de `avatar`
> no OpenAPI. Nada a reconciliar aqui.

### C. Reescrever `useVotingData` para HTTP

Substituir o mock por chamadas reais:

- Extrair/−reusar o helper de base de URL (`apiUrl` com SSR interno vs. público)
  hoje isolado em `useAuth.ts` — as chamadas de dados precisam da mesma lógica.
  Considerar um `useApi()` compartilhado.
- **Leituras** (`currentEvent`, `closedEvents`, `events`, `participants`,
  `getEvent`) → `useFetch`/`$fetch` nos endpoints de listagem/detalhe. Prever
  estados de **loading / erro / vazio** (hoje o mock é síncrono e as telas
  assumem dados sempre presentes).
- **Ações de admin** (`createEvent`, `closeEvent`, `addParticipant`) → `POST`/
  `PATCH` autenticados. O composable precisa dos **headers de auth** (`Bearer`),
  que hoje só existem em `useAuth`; integrar os dois.
- Recalcular `totalVotes` / `votePercent` a partir dos votos vindos da API (ou
  consumir os totais já calculados pelo backend, se o endpoint de placar os
  entregar prontos).
- Após criar/encerrar/cadastrar/votar, **revalidar** os dados (refetch) em vez de
  mutar estado local.

### D. Fluxo de voto não envia o e-mail

Em `pages/votacao.vue`, o modal coleta e valida o e-mail, mas
`addVote(eventId, participantId)` **não o repassa**. A API exige
`{ event_id, partcipant_id, email }` em `POST /votes`. Ajustar a assinatura de
`addVote` para incluir o e-mail e mapear os erros da API:

- `404` → evento/participante inexistente (`errors: [...]`).
- `422` → e-mail inválido (`errors: ['Email inválido']`).

O botão "Votar" hoje já só habilita com e-mail válido; falta tratar a resposta
(sucesso/erro) da chamada real e refletir na UI.

### E. Configuração, CORS e base da API

- `nuxt.config.ts` tem `runtimeConfig.apiBase` e `apiBaseInternal` **vazios**.
  Confirmar o wiring de `NUXT_PUBLIC_API_BASE` (browser) e
  `NUXT_API_BASE_INTERNAL` (SSR pela rede interna do Compose) — ver
  `frontend/.env.example` e `backend/compose.yaml`.
- **CORS**: garantir que o backend libera a origem do frontend para as chamadas
  do browser (há um commit de CORS; validar que a origem e os métodos/headers —
  inclusive `Authorization` — estão cobertos).

## Escopo da atividade

1. **Backend**: definir, rotear, implementar e **documentar no OpenAPI** os
   endpoints faltantes (§A): listagem e detalhe de eventos (com participantes e
   votos), leitura pública para `/votacao`, placar/apuração e a URL de relatório
   (total, por participante, por hora).
2. **Frontend**: reescrever `useVotingData` para consumir a API (§C), fazendo o
   mapeamento de contrato (§B) e integrando os headers de auth nas ações de
   admin.
3. **Frontend**: corrigir o fluxo de voto para enviar o e-mail e tratar
   respostas (§D).
4. **Frontend**: tratar loading/erro/vazio nas telas que hoje assumem dados
   síncronos (`/votacao`, `/admin`, `/admin/events`, `/admin/participants`,
   `EventVotes`).
5. **Config**: preencher/validar `apiBase`/`apiBaseInternal` e o CORS (§E).

## Fora de escopo

- Atualização **em tempo real** dos placares (WebSocket/Action Cable) — o
  desafio pede "tempo real"; tratar em atividade própria. Aqui basta refetch sob
  demanda.
- Verificação humana anti-bot no voto (além do e-mail já coletado).
- Edição/remoção de participantes (a tela é só cadastro, por escopo).

## Questões em aberto

- **Superfície pública de leitura**: endpoints públicos dedicados (`GET /events`,
  `GET /events/{id}`, `GET /events/{id}/results`) ou reaproveitar as rotas admin
  sem exigir token? Definir antes de implementar.
- **Formato do placar**: o backend devolve os totais já calculados (contagem e
  %) ou só a contagem bruta e o frontend calcula o %? (Hoje o mock calcula.)
- **Relatório por hora**: granularidade e recorte (por evento? global?) da URL
  de relatório do desafio.

## Critérios de aceite

- Nenhuma tela de produto depende mais do mock de `useVotingData`; todas leem da
  API.
- `/votacao` lista o evento aberto e os encerrados vindos do backend e registra
  voto real (com e-mail) em `POST /votes`.
- Admin cria/encerra evento e cadastra participante via API autenticada, e as
  listas refletem o backend após cada ação.
- Placar (`EventVotes`) mostra votos/percentuais vindos do backend.
- Todos os endpoints novos estão descritos no `openapi.yaml`.
- Existe uma URL de relatório com total, total por participante e votos por hora.
