# 003 - Identidade visual e aparência do sistema

## Contexto
O **Paredão BBB 26.5** é um sistema de votação de público voltado para grande
audiência: a maior parte dos acessos vem de eleitores anônimos, em dispositivos
variados, que precisam votar rápido e entender o resultado num relance. O
frontend é um app **Nuxt 4 SSR** desacoplado do backend, que fala com a API
apenas via HTTP (`NUXT_PUBLIC_API_BASE`).

Esta atividade define a **identidade visual e as diretrizes de aparência** do
frontend — o "look and feel" que deve ser aplicado de forma consistente em
todas as telas. Não trata de regras de negócio nem de integração com a API;
trata de como o sistema se apresenta ao usuário.

O sistema tem duas grandes regiões, com públicos diferentes:
- **Área pública** (votação e resultados) — anônima, alto volume, foco em
  clareza e leveza.
- **Área administrativa** (gestão do paredão) — restrita a administradores
  autenticados (ver `docs/tasks/002-authentication.md` e
  `docs/tasks/004-login-admin.md`).

## Objetivo
Estabelecer um tema visual **claro (light) e divertido**, com componentes
animados e consistentes, e definir uma **área de anúncios** reservada nas
telas públicas. O resultado deve ser um conjunto de diretrizes e componentes
base reutilizáveis, de modo que as telas seguintes já nasçam dentro do padrão.

## Requisitos

1. **Tema claro e divertido.** Adotar um tema `light` como padrão do sistema,
   com uma linguagem visual descontraída (paleta viva, cantos arredondados,
   tipografia amigável) coerente com o universo do programa. O tema deve ser
   centralizado (tokens de cor, espaçamento, tipografia e raios) e não
   espalhado/hardcoded pelas telas, para manter consistência.

2. **Botões animados.** Todos os botões devem ter animação de interação
   (ex.: transições de `hover`, `active`/`press` e `focus`, e feedback de
   estado de carregamento quando a ação for assíncrona). As animações devem ser
   sutis, rápidas e consistentes entre si — nunca prejudicar a legibilidade ou
   a percepção de resposta imediata ao clique.

3. **Acessibilidade e responsividade.** O tema deve funcionar bem em telas de
   celular e desktop (mobile-first) e respeitar contraste mínimo legível.
   As animações devem honrar a preferência do usuário por movimento reduzido
   (`prefers-reduced-motion`), degradando para transições mínimas quando essa
   preferência estiver ativa.

4. **Área de anúncios.** Todas as telas da **área pública** — isto é, telas não
   logadas e que não pertencem à área do administrador — devem **reservar o
   rodapé para uma área de anúncios**. Requisitos:
   - O espaço do rodapé é reservado de forma consistente em todas as telas
     públicas (mesma posição e dimensões), independentemente de haver anúncio
     no momento.
   - Enquanto **não houver anúncio** para exibir, mostrar a mensagem de
     preenchimento (placeholder): **"anuncie aqui - telefone: 224 4000"**.
   - A área administrativa **não** exibe anúncios.

## Definições
- **Tema `light`** — esquema visual claro adotado como padrão do sistema,
  definido por tokens centralizados (cor, tipografia, espaçamento, raios).
- **Área pública** — qualquer tela acessível sem autenticação (votação e
  resultados). Reserva o rodapé para anúncios.
- **Área administrativa** — telas restritas a administradores autenticados.
  Não exibe a área de anúncios.
- **Área de anúncios** — faixa reservada no rodapé das telas públicas para
  exibição de anúncios; exibe o placeholder quando não há anúncio.

## Entregável
- Tema `light` e divertido aplicado ao frontend, com tokens de estilo
  centralizados e reutilizáveis.
- Componente de botão (ou diretriz aplicada aos botões) com animações de
  interação padronizadas.
- Componente de rodapé com a área de anúncios reservada nas telas públicas,
  exibindo o placeholder **"anuncie aqui - telefone: 224 4000"** quando vazio.

## Critérios de aceite
- [ ] O sistema usa um tema claro (`light`) por padrão, com aparência
      descontraída e consistente entre as telas.
- [ ] Os estilos vêm de tokens/definições centralizados, sem valores de tema
      espalhados/hardcoded pelas telas.
- [ ] Todos os botões apresentam animação de interação (hover/active/focus) e
      feedback visual coerente.
- [ ] O layout se adapta a mobile e desktop e mantém contraste legível.
- [ ] Com `prefers-reduced-motion` ativo, as animações degradam para o mínimo.
- [ ] Toda tela da área pública reserva o rodapé para anúncios, com posição e
      dimensões consistentes.
- [ ] Sem anúncio, o rodapé público exibe exatamente
      "anuncie aqui - telefone: 224 4000".
- [ ] A área administrativa não exibe a área de anúncios.
