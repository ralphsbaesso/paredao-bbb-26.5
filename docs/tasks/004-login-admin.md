# 004 - Tela de login do administrador

## Contexto
O **Paredão BBB 26.5** separa dois públicos: os eleitores anônimos (votação e
resultados, sem login) e os **administradores**, que operam a área de gestão
(abrir/encerrar paredões, cadastrar participantes, consultar relatórios). Toda a
autenticação do sistema é destinada **exclusivamente aos administradores** — não
há usuário votante nem cadastro público (ver `docs/tasks/002-authentication.md`
e `docs/estudo-modelagem-backend.md`).

O backend já expõe a autenticação de administradores em modo **API-only**
(login/logout por token, entidade `AdminUser`, rotas administrativas protegidas
por `401` — ver `docs/tasks/002-authentication.md`). Esta atividade cobre o lado
do **frontend Nuxt 4 SSR**: a tela por onde o administrador se autentica para
acessar a área de gestão.

## Objetivo
Criar a **tela de login do administrador** no frontend, consumindo o endpoint de
autenticação do backend, armazenando a credencial recebida e liberando o acesso
à área administrativa. A tela é o único ponto de entrada da área restrita: **só
login**, sem recuperação de senha e sem cadastro de novo usuário.

## Requisitos

1. **Somente login.** A tela contém apenas o formulário de autenticação
   (identificador/e-mail e senha) e a ação de entrar. **Não** deve haver:
   - link/fluxo de "esqueci minha senha";
   - link/fluxo de "cadastrar novo usuário" ou auto-registro;
   - qualquer outra navegação para fora do fluxo de login.

2. **Rota de acesso pouco descobrível.** Por ser um acesso administrativo, a URL
   não deve ser adivinhável por intuição (evitar `/admin`, `/login`, etc.). Usar
   exatamente:

   ```
   /local-extremamente-seguro-contra-hacker/admin
   ```

   > Observação: uma rota "secreta" é apenas ofuscação, **não** é controle de
   > segurança. A proteção real continua sendo a autenticação por token no
   > backend (`401` em rota protegida sem credencial válida). A rota difícil
   > apenas reduz descoberta acidental.

3. **Tema dark (exceção à identidade visual).** A área administrativa pode usar
   um tema **`dark`**, distinto do tema `light` padrão das telas públicas
   definido em `docs/tasks/003-style.md`. O tema dark deve reutilizar os
   **tokens centralizados** (cor, tipografia, espaçamento, raios) — não valores
   hardcoded — e a tela **não** exibe a área de anúncios (ela é administrativa,
   não pública).

4. **Integração com a autenticação do backend.** Ao enviar o formulário, a tela
   chama o endpoint de login da API (`NUXT_PUBLIC_API_BASE`, injetado em
   runtime) com as credenciais. Em caso de sucesso:
   - armazenar a credencial (token/sessão) recebida e reutilizá-la nas chamadas
     seguintes via header `Authorization`;
   - redirecionar o administrador para a área de gestão.

   Em caso de credenciais inválidas (`401`), exibir mensagem de erro clara e
   permanecer na tela, **sem** vazar detalhes sobre o motivo da falha
   (ex.: não revelar se o e-mail existe).

5. **Feedback e estados de UI.** O botão de entrar segue o padrão de botões
   animados da `003` (hover/active/focus) e apresenta **estado de carregamento**
   enquanto a requisição está em andamento, evitando envios duplicados. Campos
   obrigatórios validados antes do envio.

6. **Proteção da área administrativa no frontend.** Rotas da área de gestão só
   são acessíveis com credencial válida; um acesso sem credencial (ou com
   credencial expirada/inválida, sinalizada por `401` do backend) redireciona
   para esta tela de login. O logout invalida a credencial e retorna à tela de
   login.

## Definições
- **Tela de login do administrador** — única porta de entrada da área
  administrativa; contém apenas o formulário de autenticação.
- **Rota secreta** — caminho pouco descobrível
  (`/local-extremamente-seguro-contra-hacker/admin`) que serve de ofuscação, não
  de controle de acesso.
- **Tema `dark`** — variante visual escura da área administrativa, baseada nos
  mesmos tokens centralizados do tema `light`.
- **Área administrativa** — telas restritas a administradores autenticados; não
  exibem anúncios (ver `docs/tasks/003-style.md`).

## Entregável
- Tela de login do administrador no frontend, acessível em
  `/local-extremamente-seguro-contra-hacker/admin`, com tema `dark` e apenas o
  formulário de login (sem recuperação de senha nem cadastro).
- Integração com o endpoint de autenticação do backend: envio de credenciais,
  armazenamento e reutilização da credencial, e redirecionamento para a área de
  gestão no sucesso.
- Tratamento de erro para credenciais inválidas (`401`) e proteção das rotas
  administrativas com redirecionamento para o login.

## Critérios de aceite
- [ ] A tela de login está acessível em
      `/local-extremamente-seguro-contra-hacker/admin` e não em rotas
      intuitivas como `/admin` ou `/login`.
- [ ] A tela contém **somente** o formulário de login — não há "esqueci minha
      senha" nem "cadastrar novo usuário".
- [ ] A área administrativa usa tema `dark`, derivado dos tokens centralizados,
      e não exibe a área de anúncios.
- [ ] Login com credenciais válidas autentica, armazena a credencial e
      redireciona para a área de gestão.
- [ ] Login com credenciais inválidas exibe erro claro e permanece na tela, sem
      vazar detalhes da falha.
- [ ] O botão de entrar tem animação de interação e estado de carregamento,
      impedindo envios duplicados.
- [ ] Acesso a uma rota administrativa sem credencial válida (ou com `401` do
      backend) redireciona para a tela de login.
- [ ] O logout invalida a credencial e retorna à tela de login.
