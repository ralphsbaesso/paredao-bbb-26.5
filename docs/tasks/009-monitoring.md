# 009 - Monitoramento da aplicação

## Contexto
O desafio (ver `../desafio-tecnico-fullstack.md`) exige **monitoração da API** e
**dashboards da monitoração** entre os itens obrigatórios, e nos diferenciais
pede ainda: **definir um SLO e calcular um SLI** (exibidos em dashboard), **logs
estruturados** (Warning, Erro, Debug e Info — com ao menos uma execução com erro
registrada) e o uso de uma **ferramenta de métricas** (ex.: Prometheus) com
**3 dashboards em tempo real** das métricas instrumentadas na aplicação.

Esta atividade cobre a camada de **observabilidade** do projeto: instrumentar a
API, coletar as métricas e apresentá-las em dashboards.

## Objetivo
Subir uma stack de monitoramento baseada em **Grafana + Prometheus** integrada ao
projeto via `compose.yaml` da raiz, coletando as métricas expostas pela API e
apresentando-as em dashboards em tempo real, incluindo o SLO/SLI definido.

## Escopo
- **Dentro do escopo:** instrumentação da API (endpoint de métricas), coleta via
  Prometheus, visualização via Grafana, dashboards e a definição de SLO/SLI.
- **Fora do escopo:** alertas/paging, monitoramento do frontend e provisionamento
  em cloud (a stack roda localmente via Compose).

---

## Componentes
- **Prometheus** — coleta (scrape) das métricas expostas pela API.
- **Grafana** — dashboards conectados ao Prometheus como data source.
- **Instrumentação da API** (`backend/`) — expor um endpoint de métricas no
  formato Prometheus (ex.: `/metrics`) com, no mínimo:
  - taxa de requisições, latência (percentis) e taxa de erros por rota;
  - contador de votos (métrica de negócio, alinhada ao alvo de ~1000 votos/s).

## SLO / SLI
- **Definir um SLO** para o fluxo crítico (votação) — ex.: *99% das requisições
  de voto respondidas com sucesso em < X ms numa janela de tempo*.
- **Calcular o SLI** correspondente a partir das métricas coletadas.
- **Exibir** SLO e SLI em um dashboard.

## Dashboards (mínimo 3, em tempo real)
1. **Saúde da API** — requisições/s, latência (p50/p95/p99), taxa de erros.
2. **Negócio** — votos por segundo/minuto e total de votos por participante.
3. **SLO/SLI** — orçamento de erro (error budget) e cumprimento do SLO.

## Logs estruturados
Garantir que a API gere logs nos níveis **Warning, Erro, Debug e Info**, com ao
menos **uma situação de execução com erro** registrada no log (requisito Extra 1
do desafio).

---

## Entregável
- Serviços `prometheus` e `grafana` adicionados ao `compose.yaml` da raiz,
  integrados à rede dos demais serviços e com persistência de dados/configuração.
- Configuração do Prometheus (targets/scrape da API) versionada no repositório.
- Grafana provisionado com o Prometheus como data source e os dashboards acima
  versionados (provisioning as code, não criados só pela UI).
- API expondo o endpoint de métricas e emitindo logs estruturados nos 4 níveis.
- Instruções de acesso (portas/URLs) no README ou no `.env.example`.

## Critérios de aceite
- [ ] `docker compose up` a partir da raiz sobe Prometheus e Grafana junto do
      restante do stack.
- [ ] A API expõe métricas no formato Prometheus e o Prometheus as coleta com
      sucesso (target *up*).
- [ ] O Grafana abre com o Prometheus configurado como data source.
- [ ] Existem **3 dashboards** funcionando em tempo real (saúde, negócio, SLO/SLI).
- [ ] O SLO está definido e o SLI é calculado e exibido em dashboard.
- [ ] A API emite logs Warning, Erro, Debug e Info, com ao menos um erro real
      registrado.
- [ ] Configuração de Prometheus, data source e dashboards está versionada no
      repositório (não apenas na UI).
