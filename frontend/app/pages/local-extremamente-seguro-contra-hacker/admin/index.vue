<script setup lang="ts">
/**
 * `/admin` — Painel central da área administrativa (ver docs/tasks/008-pages.md).
 *
 * Protegido pelo middleware `admin-auth`: sem credencial válida (ou 401 do
 * backend) redireciona para o login. Apresenta dois cards de navegação:
 * Eventos e Participantes. Tema dark, sem anúncios.
 */
definePageMeta({ layout: 'admin', middleware: 'admin-auth' })

const { events, participants } = useVotingData()

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
  </AdminShell>
</template>
