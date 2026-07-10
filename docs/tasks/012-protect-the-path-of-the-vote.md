# 012 - Proteger a rota de votação (rate limiting)

## Contexto
A votação acontece em `POST /votes` (`VotesController#create` → `AddVote`), uma
rota **pública** e sem autenticação — qualquer cliente pode chamá-la. O desafio
permite que um usuário vote quantas vezes quiser, mas exige que o sistema
**resista a votos automatizados (bots)** e suporte alta vazão (~1000 votos/s no
pico). Hoje não há nenhuma proteção: um script consegue disparar milhares de
requisições por segundo a partir de uma única origem.

Esta atividade adiciona **rate limiting por origem** à rota de votação, para
frear abuso automatizado sem impedir o uso legítimo (um humano vota em ritmo
muito abaixo do limite).

## Objetivo
Limitar a frequência de votos aceitos por origem, de forma configurável, e
responder com **429 Too Many Requests** quando o limite for excedido — antes de
persistir o voto.

## Escopo
- Alvo: exclusivamente `POST /votes` (`VotesController#create`).
- A verificação deve ocorrer **antes** de `AddVote.call`, para que requisições
  bloqueadas não gerem escrita no banco nem incrementem métricas de voto.

## Estratégia

### Identificação da origem
Cada requisição é atribuída a uma **origem**, usada como chave do rate limiter.
A origem é o **IP do cliente** (`request.remote_ip`). Como a API roda atrás de
proxy/load balancer, garantir que o IP real seja resolvido (cabeçalhos
`X-Forwarded-For` / `trusted_proxies` conforme a configuração de rede).

> Decisão: usar IP como identificador (e não o `email` do payload), pois o email
> é controlado pelo cliente e trivialmente forjável por um bot. Escopar a chave
> por evento é opcional — ver "Chave do Redis".

### Contagem e janela (Redis)
Usar o **Redis** (já disponível via `REDIS_URL` no `.env.example` e no
`compose.yaml`) como contador com janela deslizante de 1 segundo:

1. Montar a chave a partir da origem (ex.: `vote_rl:<ip>`).
2. `INCR` na chave.
3. Se o valor retornado for `1` (primeira requisição da janela), aplicar
   `EXPIRE <chave> <janela_em_segundos>` (por padrão, 1s).
4. Se o valor retornado **exceder** o limite configurado, responder `429` e
   **não** processar o voto.
5. Caso contrário, seguir o fluxo normal (`AddVote.call`).

> Nota: a versão anterior desta atividade descrevia "gravar a origem no Redis
> após votar e bloquear se já existir", o que só permite 1 voto por janela e
> grava tarde demais. A abordagem por contador (`INCR`/`EXPIRE`) suporta "N
> votos por segundo" e é avaliada **antes** de persistir. Preferir esta.

### Chave do Redis
- Mínimo: `vote_rl:<ip>`.
- Recomendado (opcional): escopar por evento — `vote_rl:<event_id>:<ip>` — para
  que o limite seja por paredão, não global.

## Configuração
- Criar a variável no `.env.example` (com valor padrão documentado).
- A variável define o **número máximo de requisições por segundo por origem**.
- Se não definida, o padrão é **1 requisição por segundo** (1:1).
- Sugestão de nome: `VOTE_RATE_LIMIT_RPS` (padrão `1`). Se também for desejável
  ajustar a janela, expor `VOTE_RATE_LIMIT_WINDOW_SECONDS` (padrão `1`).

Exemplo para o `.env.example`:
```env
# Rate limiting da rota pública POST /votes.
# Máximo de requisições por segundo por origem (IP). Padrão: 1 req/s (1:1).
VOTE_RATE_LIMIT_RPS=1
```

## Bypass para teste de carga
Requisições que incluam o header **`load-test: True`** devem **ignorar o rate
limiting** e seguir direto para o fluxo de votação. Isso é necessário para os
testes de carga do desafio (~1000 votos/s), que disparam muitas requisições da
mesma origem e seriam bloqueados pelo limiter.

- A checagem do header ocorre **antes** da lógica de rate limiting (nem `INCR`
  nem `EXPIRE` são executados quando o bypass está ativo).
- Comparação do valor **case-insensitive** (aceitar `True`/`true`).
- Registrar um log (nível `info` ou `debug`) indicando que o voto passou em modo
  de teste de carga, para não confundir com tráfego real nas métricas/análises.

> Atenção (segurança): esse header desativa a proteção anti-bot. Em produção ele
> é um vetor de abuso trivial. Recomenda-se **restringi-lo** — habilitá-lo apenas
> quando `Rails.env` não for produção, ou exigir um segredo compartilhado
> (ex.: `load-test: <token>` validado contra uma env var) em vez de um valor
> fixo. Definir essa política ao implementar.

## Resposta ao exceder o limite
- HTTP **429 Too Many Requests**.
- Corpo JSON no mesmo formato de erro já usado pelo controller, ex.:
  `{ "errors": ["Muitas requisições. Tente novamente em instantes."] }`.
- Opcional (boa prática): incluir o header `Retry-After` com os segundos até a
  liberação.
- Registrar um log **`warn`** estruturado no bloqueio (padrão de logs do
  projeto: `event:`, mais contexto), ex.:
  `event: 'vote.rate_limited', ip: ..., event_id: ...`.

## Dependências técnicas
- Adicionar o gem `redis` ao `Gemfile` (ainda não está presente) e um cliente
  Redis configurado a partir de `REDIS_URL`.
- Falha do Redis não deve derrubar a votação: definir o comportamento em caso de
  indisponibilidade (recomendado **fail-open** — permitir o voto e logar `error`
  — para não bloquear votos legítimos por um problema de infra).

> Alternativa a considerar: o Rails 8 oferece `rate_limit` nativo em controllers,
> backed pelo cache store (poderia usar Solid Cache, alinhado ao "stack Solid /
> sem Redis" descrito no CLAUDE.md). Como o Redis já está provisionado no
> compose, esta atividade segue com Redis, mas a decisão pode ser revisitada.

## Critérios de aceite
- [ ] Requisições a `POST /votes` acima do limite configurado recebem `429` e
      **não** criam registro de `Vote` nem incrementam a métrica de votos.
- [ ] Requisições dentro do limite continuam funcionando normalmente (`201`).
- [ ] O limite é configurável via variável de ambiente, com padrão de 1 req/s
      quando ausente, e documentado no `.env.example`.
- [ ] A verificação ocorre **antes** de `AddVote.call`.
- [ ] Requisições com o header `load-test: True` ignoram o rate limiting e
      votam normalmente, mesmo acima do limite.
- [ ] Um log `warn` estruturado é emitido a cada bloqueio.
- [ ] Indisponibilidade do Redis não impede votos legítimos (comportamento
      definido e testado).
- [ ] Specs cobrindo: dentro do limite, acima do limite (429), reset após a
      janela, e Redis indisponível.
