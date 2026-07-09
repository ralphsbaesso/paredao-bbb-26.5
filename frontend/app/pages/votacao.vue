<script setup lang="ts">
/**
 * `/votacao` — Votação (ver docs/tasks/008-pages.md).
 *
 * Área pública. Duas seções lado a lado:
 *   1. Evento atual (aberto) com 2–4 participantes. Clicar num participante abre
 *      o modal de confirmação de voto, cujo botão "Votar" só habilita após um
 *      e-mail válido.
 *   2. Votações anteriores (eventos encerrados) em cards; clicar abre o modal de
 *      resumo com os votos por participante. Sem eventos encerrados, a seção some.
 *
 * Dados MOCKADOS (sem backend nesta atividade).
 */
import type { Participant, VotingEvent } from '~/composables/useVotingData'

useHead({ title: 'Votação · Paredão BBB 26.5' })

const { currentEvent, closedEvents, addVote } = useVotingData()

const nf = new Intl.NumberFormat('pt-BR')
// timeZone fixo p/ saída determinística (evita divergência de hidratação SSR).
const df = new Intl.DateTimeFormat('pt-BR', {
  dateStyle: 'long',
  timeStyle: 'short',
  timeZone: 'America/Sao_Paulo',
})

// --- Modal de confirmação de voto ------------------------------------------
const voteModalOpen = ref(false)
const selectedParticipant = ref<Participant | null>(null)
const email = ref('')
const voteConfirmed = ref(false)

const emailValid = computed(() => isValidEmail(email.value))

function openVote(participant: Participant) {
  selectedParticipant.value = participant
  email.value = ''
  voteConfirmed.value = false
  voteModalOpen.value = true
}

function confirmVote() {
  if (!emailValid.value || !currentEvent.value || !selectedParticipant.value) return
  addVote(currentEvent.value.id, selectedParticipant.value.id)
  voteConfirmed.value = true
}

// --- Modal de resumo de evento anterior ------------------------------------
const summaryModalOpen = ref(false)
const summaryEvent = ref<VotingEvent | null>(null)

function openSummary(event: VotingEvent) {
  summaryEvent.value = event
  summaryModalOpen.value = true
}
</script>

<template>
  <main class="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6">
    <h1 class="mb-6 text-3xl font-extrabold tracking-tight text-content">Votação</h1>

    <div class="grid gap-8 lg:grid-cols-2">
      <!-- 1. Evento atual -->
      <section aria-labelledby="atual-title">
        <h2 id="atual-title" class="mb-4 text-xl font-bold text-content">
          Votação em andamento
        </h2>

        <div
          v-if="currentEvent"
          class="rounded-[var(--radius-card)] border border-line bg-surface p-5 shadow-sm"
        >
          <p class="mb-1 text-sm font-semibold uppercase tracking-wide text-primary">
            {{ currentEvent.name }}
          </p>
          <p class="mb-5 text-sm text-muted">
            Quem deve ficar? Toque em um participante para votar.
          </p>

          <ul class="grid grid-cols-2 gap-4">
            <li v-for="p in currentEvent.participants" :key="p.id">
              <button
                type="button"
                class="group flex w-full flex-col items-center gap-2 rounded-[var(--radius-card)] border border-line bg-surface-muted p-4 text-center transition hover:-translate-y-1 hover:border-primary hover:shadow-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                @click="openVote(p)"
              >
                <Avatar
                  :variant="p.avatar"
                  :size="72"
                  class="text-primary transition group-hover:scale-105"
                  decorative
                />
                <span class="font-bold text-content">{{ p.name }}</span>
                <span class="text-xs font-semibold text-primary opacity-0 transition group-hover:opacity-100">
                  Votar →
                </span>
              </button>
            </li>
          </ul>
        </div>

        <!-- Estado vazio: nenhum paredão aberto. -->
        <div
          v-else
          class="rounded-[var(--radius-card)] border border-dashed border-line bg-surface p-8 text-center text-muted"
        >
          <p class="font-semibold text-content">Nenhuma votação aberta no momento.</p>
          <p class="mt-1 text-sm">Volte em breve para o próximo paredão.</p>
        </div>
      </section>

      <!-- 2. Votações anteriores (oculta quando não há eventos encerrados) -->
      <section v-if="closedEvents.length" aria-labelledby="anteriores-title">
        <h2 id="anteriores-title" class="mb-4 text-xl font-bold text-content">
          Votações anteriores
        </h2>

        <ul class="flex flex-col gap-3">
          <li v-for="event in closedEvents" :key="event.id">
            <button
              type="button"
              class="flex w-full items-center justify-between gap-4 rounded-[var(--radius-card)] border border-line bg-surface p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              @click="openSummary(event)"
            >
              <div class="min-w-0">
                <p class="font-bold text-content">{{ event.name }}</p>
                <p class="text-sm text-muted">
                  Encerrado
                  <template v-if="event.closedAt"> em {{ df.format(new Date(event.closedAt)) }}</template>
                </p>
              </div>
              <span class="shrink-0 text-sm font-semibold text-primary">Ver resumo →</span>
            </button>
          </li>
        </ul>
      </section>
    </div>

    <!-- Modal: confirmação de voto -->
    <BaseModal v-model="voteModalOpen" :title="voteConfirmed ? 'Voto registrado!' : 'Confirmar voto'">
      <template v-if="selectedParticipant && !voteConfirmed">
        <div class="flex flex-col items-center gap-2 text-center">
          <Avatar :variant="selectedParticipant.avatar" :size="80" class="text-primary" decorative />
          <p class="text-muted">
            Você está votando em
            <strong class="text-content">{{ selectedParticipant.name }}</strong>.
          </p>
        </div>

        <div class="mt-5 flex flex-col gap-1.5">
          <label for="vote-email" class="text-sm font-semibold text-content">
            Seu e-mail
          </label>
          <input
            id="vote-email"
            v-model="email"
            type="email"
            inputmode="email"
            autocomplete="email"
            placeholder="voce@exemplo.com"
            class="rounded-[var(--radius-control)] border border-line bg-surface-muted px-3 py-2.5 text-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/40"
          />
          <p class="text-xs text-muted">
            Informe um e-mail válido para liberar o botão de votar.
          </p>
        </div>
      </template>

      <template v-else-if="selectedParticipant">
        <div class="flex flex-col items-center gap-3 py-2 text-center">
          <div class="grid h-16 w-16 place-items-center rounded-full bg-primary/15 text-primary">
            <svg viewBox="0 0 24 24" width="34" height="34" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 6L9 17l-5-5" />
            </svg>
          </div>
          <p class="text-content">
            Obrigado! Seu voto em
            <strong>{{ selectedParticipant.name }}</strong> foi computado.
          </p>
          <p class="text-sm text-muted">Você pode votar quantas vezes quiser.</p>
        </div>
      </template>

      <template #footer>
        <AppButton v-if="voteConfirmed" @click="voteModalOpen = false">Fechar</AppButton>
        <template v-else>
          <AppButton variant="ghost" @click="voteModalOpen = false">Cancelar</AppButton>
          <AppButton :disabled="!emailValid" @click="confirmVote">Votar</AppButton>
        </template>
      </template>
    </BaseModal>

    <!-- Modal: resumo de evento anterior -->
    <BaseModal v-model="summaryModalOpen" :title="summaryEvent?.name">
      <template v-if="summaryEvent">
        <p class="mb-4 text-sm text-muted">
          Encerrado
          <template v-if="summaryEvent.closedAt">
            em {{ df.format(new Date(summaryEvent.closedAt)) }}
          </template>
          · {{ nf.format(summaryEvent.participants.length) }} participantes
        </p>
        <EventVotes :event="summaryEvent" />
      </template>
      <template #footer>
        <AppButton @click="summaryModalOpen = false">Fechar</AppButton>
      </template>
    </BaseModal>
  </main>
</template>
