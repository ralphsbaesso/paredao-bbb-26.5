# 005 - Componente de avatar (lista de rostos)

## Contexto
No **Paredão BBB 26.5** cada participante em disputa é exibido na tela de votação
e nos resultados. Os participantes são cadastrados pelo administrador e chegam ao
frontend **dinamicamente via API** (`NUXT_PUBLIC_API_BASE`, injetado em runtime).
Para não depender de upload de fotos nem de arquivos de imagem externos, cada
participante é representado por um **avatar vetorial** — um rosto simples,
estilo emoji — escolhido a partir de um nome recebido do backend.

## Objetivo
Criar um **componente Vue de avatar** no frontend Nuxt 4 SSR que renderiza um
rosto humano estilizado em **SVG inline**, selecionado por um **nome de variante**
recebido dinamicamente do backend. O componente deve oferecer **30 variantes
distintas** e ser reutilizável em qualquer tela que precise representar um
participante.

## Requisitos

1. **Componente Vue reutilizável.** Um único componente (ex.: `<Avatar>`) que
   recebe por prop o nome da variante e renderiza o rosto correspondente. O
   consumidor não precisa conhecer o SVG interno — apenas informa a variante.

2. **Seleção por nome de variante.** A prop principal é o **nome** da variante
   (string), não um índice numérico. O backend envia esse nome junto dos dados do
   participante; o componente resolve o SVG a partir dele.
   - Nomes de variante estáveis e previsíveis (ex.: `sun`, `moon`, `star`…), de
     forma que backend e frontend compartilhem o mesmo vocabulário.

3. **Renderização em SVG inline.** Cada avatar é uma tag **`<svg>`** embutida no
   DOM (não `<img src>` nem arquivo externo), permitindo herdar cor via
   `currentColor`, escalar sem perda e ser estilizado pelos tokens centralizados
   de `docs/tasks/003-style.md`.

4. **Estética de rosto simples (estilo emoji).** Cada variante representa um
   **rosto humano** minimalista — traços simples (contorno do rosto, olhos, boca),
   próximo de um emoji. Nada de retrato realista ou detalhamento excessivo; o
   objetivo é reconhecível e leve.

5. **30 variantes distintas.** Devem existir **30** rostos visualmente
   diferentes entre si (variando traços como formato do rosto, olhos, boca,
   expressão). Cada variante tem um nome único.

6. **Tamanho e cor controláveis.** O tamanho deve ser controlável pelo consumidor
   (via prop e/ou CSS) e a cor deve seguir os tokens centralizados, funcionando
   nos temas `light` (público) e `dark` (administrativo) sem valores hardcoded.

7. **Comportamento com variante ausente/inválida.** Se o nome recebido não
   corresponder a nenhuma variante conhecida, o componente exibe um **avatar de
   fallback** previsível (em vez de quebrar a renderização).

8. **Acessibilidade.** O SVG deve ser acessível: rótulo adequado (ex.: `role`
   e `aria-label` com o nome do participante) ou marcado como decorativo
   (`aria-hidden`) quando o nome já estiver visível ao lado.

## Definições
- **Avatar** — rosto humano estilizado em SVG inline que representa um
  participante na UI.
- **Variante** — um dos 30 rostos distintos, identificado por um **nome** único e
  estável compartilhado entre backend e frontend.
- **Fallback** — avatar padrão exibido quando o nome de variante é ausente ou
  desconhecido.

## Entregável
- Componente Vue de avatar no frontend que renderiza um rosto em SVG inline a
  partir de um nome de variante recebido por prop.
- **30 variantes** de rosto distintas, cada uma com nome único, com tamanho e cor
  controláveis pelos tokens centralizados e suporte aos temas `light` e `dark`.
- Tratamento de variante inválida via avatar de fallback e marcação de
  acessibilidade adequada.

## Critérios de aceite
- [ ] Existe um componente Vue de avatar que recebe o **nome da variante** por
      prop e renderiza o rosto correspondente.
- [ ] O avatar é renderizado como **`<svg>` inline** (não `<img>` nem arquivo
      externo).
- [ ] Cada avatar representa um **rosto humano simples**, no estilo emoji.
- [ ] Existem **30 variantes** visualmente distintas, cada uma com nome único.
- [ ] Tamanho e cor são controláveis e seguem os tokens centralizados,
      funcionando nos temas `light` e `dark`.
- [ ] Um nome de variante ausente ou desconhecido exibe o **avatar de fallback**,
      sem quebrar a renderização.
- [ ] O avatar tem marcação de acessibilidade adequada (rótulo ou `aria-hidden`).
