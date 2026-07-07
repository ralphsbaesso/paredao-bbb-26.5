# paredao-bbb-26.5

Sistema de votação do "paredão" do BBB. Monorepo com serviços independentes e
desacoplados: `backend/` (API Rails 8.1, API-only) e `frontend/` (Nuxt 4 SSR,
planejado). Backend e frontend se comunicam **apenas via HTTP** — a URL da API é
injetada no frontend em runtime através de `NUXT_PUBLIC_API_BASE` (nunca
hardcoded).

A votação do público é **anônima e ilimitada** (não há login de eleitor). A
autenticação descrita abaixo é **exclusiva de administradores**, que operam a
área de gestão (paredões, participantes, relatórios).

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
