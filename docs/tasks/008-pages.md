# 008 - Estrutura de Páginas do Frontend

## Contexto
O frontend do **Paredão BBB 26.5** já está com o setup concluído (ver task 001).
Esta atividade define a **estrutura de páginas e a navegação** entre elas,
cobrindo tanto a área pública de votação quanto a área administrativa.

Os domínios envolvidos são **Event** (evento/paredão de votação) e
**Participant** (participante que recebe votos).

## Objetivo
Entregar todas as páginas e o fluxo de navegação do frontend, com os
componentes de UI (modais, cards, formulários) funcionando localmente.

## Escopo
- **Dentro do escopo:** rotas, layouts, navegação, componentes visuais, estados
  de tela (vazio, aberto, encerrado) e validações de formulário no cliente.
- **Fora do escopo:** integração real com o **backend**. Nesta atividade não há
  chamadas de API — as telas devem trabalhar com **dados mockados/estáticos**.
  A conexão com a API será tratada em atividade posterior.

---

## Área pública (não autenticada)
É a área de votação e **não exige autenticação**.

| Rota | Descrição |
|------|-----------|
| `/` | Raiz — apresentação do programa |
| `/votacao` | Seção de votação |

**Rodapé (obrigatório em toda a área pública):** deve reservar um espaço para
anúncios. Sem anúncio cadastrado no momento, exibir o texto:
`anuncie aqui - telefone: 224 4000`.

### `/` — Apresentação
Página inicial com a apresentação do programa e **um único botão** para iniciar
a votação. Ao clicar no botão, o usuário é levado para `/votacao`.

### `/votacao` — Votação
A página tem **duas seções dispostas horizontalmente**.

**1. Evento atual (votação em andamento)**
- Exibe o **Event** de votação atual e seus participantes (de **2 a 4**
  `Participant`).
- Ao clicar no participante desejado, abre-se um **modal de confirmação de voto**.
- No modal, o usuário deve preencher um campo **e-mail** com um endereço válido.
- O botão **Votar** permanece **desabilitado** até que o e-mail seja validado;
  após a validação, ele fica habilitado para clique.

**2. Votações anteriores**
- Lista os eventos **já encerrados**, cada um representado por um **card** com o
  nome do evento.
- Se **não houver** eventos anteriores, a seção inteira fica **oculta**.
- Ao clicar em um card, abre-se um **modal com o resumo do evento**: data/estado
  de encerramento e a **quantidade de votos de cada participante**.

---

## Área administrativa (autenticada)
Rotas prefixadas por um caminho propositalmente obscuro
(`local-extremamente-seguro-contra-hacker`) como camada mínima de ofuscação.

| Rota | Descrição |
|------|-----------|
| `local-extremamente-seguro-contra-hacker/admin/login` | Tela de login |
| `local-extremamente-seguro-contra-hacker/admin` | Painel central com 2 cards: **Eventos** e **Participantes** |
| `local-extremamente-seguro-contra-hacker/admin/events` | Gerenciamento de eventos |
| `local-extremamente-seguro-contra-hacker/admin/participants` | Gerenciamento de participantes |

As rotas sob `/admin` (exceto `login`) só podem ser acessadas por um
administrador autenticado; caso contrário, redirecionar para o login.

### Gerenciar eventos (`/admin/events`)
O administrador pode:
- **Criar** um novo evento.
- **Encerrar** um evento aberto.
- **Visualizar** um evento (aberto ou encerrado), incluindo a **quantidade de
  votos de cada participante**.

### Gerenciar participantes (`/admin/participants`)
O administrador pode **apenas cadastrar** participantes.

---

## Entregável
- Todas as rotas acima criadas e navegáveis no frontend (`frontend/`).
- Modais de confirmação de voto e de resumo de evento funcionando.
- Cards de eventos anteriores e do painel administrativo.
- Estados de tela tratados (sem eventos anteriores → seção oculta; evento
  aberto vs. encerrado).
- Telas operando com dados mockados (sem chamadas ao backend).

## Critérios de aceite
- [ ] `/` exibe a apresentação e o botão que navega para `/votacao`.
- [ ] O rodapé da área pública exibe `anuncie aqui - telefone: 224 4000`.
- [ ] `/votacao` mostra o evento atual com 2 a 4 participantes.
- [ ] Clicar em um participante abre o modal de confirmação de voto.
- [ ] O botão **Votar** só habilita após um e-mail válido ser informado.
- [ ] A seção de votações anteriores fica oculta quando não há eventos encerrados.
- [ ] Clicar em um card de evento anterior abre o modal com o resumo e os votos
      por participante.
- [ ] O painel `/admin` mostra os cards **Eventos** e **Participantes**.
- [ ] Rotas `/admin` (exceto login) exigem administrador autenticado.
- [ ] Em `/admin/events` é possível criar, encerrar e visualizar um evento com
      os votos por participante.
- [ ] Em `/admin/participants` é possível cadastrar um participante.
