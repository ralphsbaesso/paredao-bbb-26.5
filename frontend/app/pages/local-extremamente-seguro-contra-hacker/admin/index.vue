<script setup lang="ts">
/**
 * `/admin` — Painel central da área administrativa (ver docs/tasks/008-pages.md).
 *
 * Protegido pelo middleware `admin-auth`: sem credencial válida (ou 401 do
 * backend) redireciona para o login. Apresenta dois cards de navegação:
 * Eventos e Participantes. Tema dark, sem anúncios.
 */
definePageMeta({ layout: 'admin', middleware: 'admin-auth' })

const { loadEvents, loadParticipants } = useVotingData()
const { events } = loadEvents()
const { participants } = loadParticipants()

const cards = computed(() => [
  {
    to: ADMIN_EVENTS_PATH,
    title: 'Eventos',
    description: 'Criar, encerrar e visualizar paredões e seus votos.',
    meta: `${events.value.length} evento(s)`,
  },
  {
    to: ADMIN_PARTICIPANTS_PATH,
    title: 'Participantes',
    description: 'Cadastrar participantes que concorrem nos paredões.',
    meta: `${participants.value.length} participante(s)`,
  },
])

const config = useRuntimeConfig()

const tools = computed(() => [
  { name: 'Swagger', href: `${config.public.apiBase}/api-docs` },
  { name: 'Grafana', href: config.public.grafanaUrl },
  { name: 'Prometheus', href: config.public.prometheusUrl },
].filter((tool) => tool.href))
</script>

<template>
  <AdminShell title="Painel administrativo">
    <div class="grid gap-5 sm:grid-cols-2">
      <NuxtLink
        v-for="card in cards"
        :key="card.to"
        :to="card.to"
        class="group flex flex-col gap-2 rounded-[var(--radius-card)] border border-line bg-surface p-6 shadow-sm transition hover:-translate-y-1 hover:border-primary hover:shadow-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
      >
        <h2 class="text-xl font-extrabold text-content">{{ card.title }}</h2>
        <p class="flex-1 text-sm text-muted">{{ card.description }}</p>
        <div class="mt-2 flex items-center justify-between">
          <span class="text-xs font-semibold uppercase tracking-wide text-muted">
            {{ card.meta }}
          </span>
          <span class="text-sm font-semibold text-primary transition group-hover:translate-x-0.5">
            Abrir →
          </span>
        </div>
      </NuxtLink>
    </div>

    <div v-if="tools.length" class="mt-10">
      <h2 class="mb-3 text-xs font-semibold uppercase tracking-wide text-muted">
        Serviços
      </h2>
      <div class="flex flex-wrap gap-3">
        <a
          v-for="tool in tools"
          :key="tool.name"
          :href="tool.href"
          target="_blank"
          rel="noopener noreferrer"
          class="group flex items-center gap-2 rounded-[var(--radius-control)] border border-line bg-surface px-4 py-2 text-sm font-semibold text-content shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
        >
          {{ tool.name }}
          <span class="text-muted transition group-hover:text-primary">↗</span>
        </a>
      </div>
    </div>
  </AdminShell>
</template>
