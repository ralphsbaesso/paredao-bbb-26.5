# 002 - Autenticação no backend

## Contexto
O **Paredão BBB 26.5** tem votação **anônima e ilimitada** — o eleitor não faz
login e não existe entidade de usuário votante (ver
`docs/estudo-modelagem-backend.md`). A autenticação desta atividade é destinada
**exclusivamente a usuários administradores**, que operarão a área de gestão
(abrir/encerrar paredões, cadastrar participantes, consultar relatórios). Não
tem relação com o fluxo de voto do público.

O backend é **Rails 8.1 API-only** (`config.api_only = true`), sem views HTML e
sem sessão baseada em cookie/redirect por padrão. A autenticação precisa ser
adequada a esse formato.

## Objetivo
Implementar autenticação no backend restrita a administradores, partindo do
gerador nativo de autenticação do Rails 8 e adaptando o resultado para o modo
**API-only**. Ao final, o backend deve expor endpoints para autenticar um
administrador e proteger as rotas administrativas, respondendo apenas em JSON.

## Requisitos

1. **Gerar a base de autenticação** com o gerador nativo do Rails 8
   (`bin/rails generate authentication`). Ele cria a estrutura de autenticação
   (modelo de usuário com senha criptografada via `has_secure_password`,
   modelo/registro de sessão, controllers de sessão e de recuperação de senha e
   o concern de autenticação).

2. **Renomear a entidade de usuário para administrador.** O recurso `users`
   gerado deve passar a se chamar `admin_users` (modelo `AdminUser`), deixando
   explícito no domínio que a autenticação é apenas para administradores. O
   ajuste deve alcançar todas as referências geradas: nome da tabela e da
   migração, modelo, associações do modelo de sessão, controllers e o concern de
   autenticação.

3. **Adaptar para API-only.** O gerador assume um app com views HTML, cookies de
   sessão e redirecionamentos. No modo API-only isso não se aplica; adaptar para:
   - **Respostas em JSON** em todos os endpoints de autenticação (sem views
     HTML, sem `flash`, sem `redirect_to`).
   - **Autenticação por token** (ex.: token de sessão ou JWT enviado no header
     `Authorization`), em vez de sessão por cookie assinado. O login deve
     devolver ao cliente a credencial a ser reutilizada nas requisições
     seguintes; o logout deve invalidá-la.
   - **Códigos de status HTTP corretos**: `401 Unauthorized` para requisição sem
     credencial ou com credencial inválida/expirada (nunca redirecionar para uma
     tela de login), e os códigos adequados para login/logout bem-sucedidos.
   - Remover ou não expor o fluxo de recuperação de senha por e-mail se ele não
     fizer sentido neste escopo; se for mantido, também deve responder em JSON.

4. **Proteger as rotas administrativas.** As rotas de gestão devem exigir um
   administrador autenticado; requisições sem credencial válida recebem `401`.
   As rotas públicas de votação e o health check (`GET /up`) permanecem abertas.

5. **Provisionar o primeiro administrador.** Como não há tela pública de
   cadastro de administrador, definir como o administrador inicial é criado
   (ex.: via `db/seeds.rb` e/ou task/rake), já que não haverá auto-registro.

6. **Segurança e configuração.** Senhas nunca em texto puro (apenas o hash do
   `has_secure_password`). Segredos e tempos de expiração de token devem vir de
   variáveis de ambiente / credenciais do Rails, nunca hardcoded. Considerar a
   necessidade de habilitar e escopar o **CORS**
   (`config/initializers/cors.rb`, hoje comentado) para permitir que o frontend
   consuma os endpoints de autenticação a partir de sua origem.

## Definições

- **`AdminUser`** — administrador do sistema. Substitui o `users` gerado.
  Autentica com identificador (e-mail) e senha; senha armazenada como hash.
- **Sessão / token** — credencial emitida no login e apresentada nas requisições
  autenticadas via header `Authorization`. Invalidada no logout.
- **Rota administrativa** — qualquer endpoint de gestão que só pode ser acessado
  por um `AdminUser` autenticado.

## Atualizar documentação

Atualizar o `README.md` da raiz do projeto descrevendo o fluxo de autenticação
de ponta a ponta:
- **Como o frontend autentica**: qual endpoint chama, o que envia (credenciais)
  e o que recebe de volta (token/credencial de sessão).
- **Como o frontend armazena e reutiliza** a credencial nas chamadas seguintes
  (header `Authorization`).
- **Como se dá a comunicação backend↔frontend após autenticado**: quais rotas
  exigem credencial, o comportamento esperado em caso de credencial ausente ou
  expirada (`401`) e como o frontend deve reagir a isso.
- Observação sobre o desacoplamento: frontend e backend se comunicam apenas via
  HTTP; a URL da API é injetada em runtime (`NUXT_PUBLIC_API_BASE`).

## Entregável
- Autenticação de administradores funcional no backend, adaptada ao modo
  API-only (JSON + token), com a entidade renomeada para `AdminUser`.
- Endpoints de login e logout, mais a proteção das rotas administrativas.
- Mecanismo de criação do administrador inicial documentado.
- `README.md` da raiz atualizado com o fluxo de autenticação e de comunicação
  backend↔frontend.

## Critérios de aceite
- [ ] Existe o modelo `AdminUser` (tabela `admin_users`); nenhuma referência
      residual a `users`/`User` do gerador permanece.
- [ ] O login com credenciais válidas retorna a credencial de autenticação em
      JSON; com credenciais inválidas retorna `401`.
- [ ] Uma rota administrativa acessada sem credencial válida retorna `401`
      (e não um redirecionamento para tela de login).
- [ ] Uma rota administrativa acessada com credencial válida responde
      normalmente.
- [ ] O logout invalida a credencial (ela deixa de ser aceita).
- [ ] Nenhum endpoint de autenticação renderiza HTML; todas as respostas são
      JSON.
- [ ] É possível criar o administrador inicial pelo mecanismo documentado.
- [ ] O `README.md` da raiz descreve o fluxo de autenticação e a comunicação
      backend↔frontend após autenticado.
```
