<script setup lang="ts">
/**
 * Placar de um evento: cada participante com seu avatar, contagem de votos e
 * percentual (ver docs/tasks/008-pages.md). Reutilizado no modal de resumo do
 * público (votações anteriores) e na visualização do evento pelo administrador.
 */
import type { VotingEvent } from '~/composables/useVotingData'

const props = defineProps<{ event: VotingEvent }>()

const { totalVotes, votePercent } = useVotingData()

const nf = new Intl.NumberFormat('pt-BR')

// Participantes ordenados do mais votado para o menos votado.
const ranked = computed(() =>
  [...props.event.participants].sort(
    (a, b) => (props.event.votes[b.id] ?? 0) - (props.event.votes[a.id] ?? 0),
  ),
)
</script>

<template>
  <div class="flex flex-col gap-3">
    <ul class="flex flex-col gap-3">
      <li v-for="p in ranked" :key="p.id" class="flex items-center gap-3">
        <Avatar :variant="p.avatar" :size="40" class="text-primary" decorative />
        <div class="min-w-0 flex-1">
          <div class="flex items-baseline justify-between gap-2">
            <span class="truncate font-semibold text-content">{{ p.name }}</span>
            <span class="shrink-0 text-sm font-bold text-primary">
              {{ votePercent(event, p.id) }}%
            </span>
          </div>
          <div class="mt-1 h-2 overflow-hidden rounded-full bg-surface-muted">
            <div
              class="h-full rounded-full bg-primary transition-[width] duration-500"
              :style="{ width: `${votePercent(event, p.id)}%` }"
            />
          </div>
          <span class="mt-1 block text-xs text-muted">
            {{ nf.format(event.votes[p.id] ?? 0) }} votos
          </span>
        </div>
      </li>
    </ul>

    <p class="border-t border-line pt-3 text-right text-sm text-muted">
      Total: <strong class="text-content">{{ nf.format(totalVotes(event)) }}</strong> votos
    </p>
  </div>
</template>
