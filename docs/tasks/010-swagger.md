# 010 - Documentação da API (Swagger / OpenAPI)

## Contexto
O backend do **Paredão BBB 26.5** é um app **Rails 8.1 API-only**, consumido
exclusivamente via HTTP pelo frontend e por eventuais integradores. O desafio
técnico exige documentação da API. Sem uma referência navegável e interativa,
cada consumidor precisa inferir contratos lendo o código dos controllers.

Esta task define **como** documentar a API via **OpenAPI/Swagger**, cobrindo os
endpoints que já existem hoje e disponibilizando uma UI interativa.

## Objetivo
Publicar um arquivo **OpenAPI 3.x estático** (`openapi.yaml`), versionado no
repositório e mantido à mão, descrevendo os endpoints atuais da API — e servi-lo
através de uma **Swagger UI** acessível em **`/api-docs`**, disponível também em
**produção** como documentação viva da API.

Não faz parte desta task gerar a documentação automaticamente a partir de specs
(rswag-specs) — o `openapi.yaml` é a fonte da verdade, escrito e revisado
manualmente.

## Tecnologias
| Tecnologia | Versão alvo | Observação |
|------------|-------------|------------|
| [OpenAPI](https://spec.openapis.org/oas/latest.html) | **3.1** (ou 3.0.x) | Formato do contrato (`openapi.yaml`), escrito à mão |
| [rswag-ui](https://github.com/rswag/rswag) | última estável | **Apenas** para servir a Swagger UI apontando para o YAML estático |
| [Swagger UI](https://swagger.io/tools/swagger-ui/) | empacotada pelo rswag-ui | Interface interativa ("Try it out") |

> **Não** utilizar `rswag-specs` nem `rswag-api` como geradores. Só o `rswag-ui`
> é necessário, e somente para servir a interface.

## Endpoints a documentar
Documentar **apenas os endpoints já roteados** hoje em
`backend/config/routes.rb`. Endpoints ainda não implementados ficam fora do
escopo desta task.

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| `POST` | `/admin/session` | Login do admin; retorna token Bearer | Pública |
| `DELETE` | `/admin/session` | Logout do admin | Bearer |
| `GET` | `/admin/profile` | Valida o token / rota protegida de exemplo | Bearer |
| `POST` | `/admin/events` | Cria um evento (paredão) | Bearer |
| `PATCH` | `/admin/events/:id/close` | Encerra um evento | Bearer |
| `GET` | `/admin/partcipants` | Lista participantes | Bearer |
| `POST` | `/admin/partcipants` | Cria participante | Bearer |
| `GET` | `/admin/partcipants/:id` | Detalha um participante | Bearer |
| `POST` | `/votes` | Registra um voto (endpoint público de alta escrita) | Pública |
| `GET` | `/up` | Health check (`rails/health#show`) | Pública |

Observações:
- ⚠️ A rota está grafada **`partcipants`** (typo no código). Documentar **como
  está** no código; a correção do nome está **fora do escopo** desta task.
- Todas as rotas sob `admin/*` (exceto o login) exigem o header
  `Authorization: Bearer <token>`. Definir um `securityScheme` **`bearerAuth`**
  (HTTP bearer) em `components/securitySchemes` e aplicá-lo a essas rotas.
- **`GET /metrics`** (Prometheus/Yabeda) **não** deve entrar no OpenAPI — não é
  uma API JSON, e sim um endpoint de scraping de métricas.

## Requisitos
1. Criar o arquivo OpenAPI estático versionado (sugestão:
   `backend/openapi/v1/openapi.yaml`), escrito à mão.
2. Descrever todos os endpoints da tabela acima, incluindo: parâmetros de path,
   corpo da requisição, respostas por status code (sucesso e principais erros —
   ex.: `401`, `404`, `422`) e exemplos.
3. Definir `components/schemas` para os payloads principais (voto, evento,
   participante, sessão/login) e reaproveitá-los via `$ref`.
4. Definir `securitySchemes.bearerAuth` e aplicá-lo às rotas `admin/*`
   autenticadas.
5. Adicionar a gem `rswag-ui` ao `Gemfile` e configurar a UI para servir em
   `/api-docs`, lendo o `openapi.yaml` versionado.
6. Manter a UI **habilitada em produção** (rota exposta em `config/routes.rb`).
7. Excluir `/metrics` do spec. Documentar `/up` é opcional.

## Servindo a UI (app API-only)
Um app `config.api_only = true` remove middlewares e não tem asset pipeline por
padrão, então servir a Swagger UI exige atenção:

- Adicionar `gem 'rswag-ui'` **fora** dos grupos `:development`/`:test` (a UI
  precisa existir em produção).
- Montar/rotear a UI em `/api-docs` e configurar o `swagger_endpoint` apontando
  para o caminho público do `openapi.yaml` (ex.: `/api-docs/v1/openapi.yaml`).
- Garantir que o middleware necessário do `rswag-ui` esteja habilitado no modo
  API-only (a UI depende de servir HTML/assets estáticos, que não vêm por padrão
  nesse modo).
- Servir o próprio arquivo `openapi.yaml` numa URL acessível pelo browser para
  que a UI consiga carregá-lo.

## Fora do escopo
- Geração automática do OpenAPI a partir de request specs (`rswag-specs`).
- Documentação de endpoints ainda não implementados.
- Correção do typo `partcipants` na rota.
- Versionamento de múltiplas versões da API (v2+).
- Inclusão do endpoint `/metrics` no contrato.

## Entregável
- `openapi.yaml` completo e válido, cobrindo todos os endpoints roteados atuais
  (exceto `/metrics`), com schemas e auth Bearer descritos.
- Swagger UI acessível em `/api-docs`, funcionando em desenvolvimento **e**
  produção.

## Critérios de aceite
- [ ] O `openapi.yaml` valida contra o schema OpenAPI 3.x (linter/validador).
- [ ] Todos os endpoints roteados atuais (exceto `/metrics`) estão descritos.
- [ ] A autenticação Bearer está descrita (`bearerAuth`) e aplicada às rotas admin.
- [ ] `GET /api-docs` renderiza a Swagger UI carregando o spec.
- [ ] A UI está acessível em produção.
- [ ] O "Try it out" da UI dispara requisições reais contra a API.
