<script setup lang="ts">
/**
 * `/admin/events` — Gestão de eventos/paredões (ver docs/tasks/008-pages.md).
 *
 * O administrador pode:
 *   - Criar um novo evento (nome + 2 a 4 participantes).
 *   - Encerrar um evento aberto.
 *   - Visualizar um evento (aberto ou encerrado) com os votos por participante.
 *
 * Dados mockados (sem backend nesta atividade).
 */
import type { VotingEvent } from '~/composables/useVotingData'

definePageMeta({ layout: 'admin', middleware: 'admin-auth' })

const { events, participants, createEvent, closeEvent, totalVotes } = useVotingData()

const nf = new Intl.NumberFormat('pt-BR')
// timeZone fixo p/ saída determinística (evita divergência de hidratação SSR).
const df = new Intl.DateTimeFormat('pt-BR', {
  dateStyle: 'short',
  timeStyle: 'short',
  timeZone: 'America/Sao_Paulo',
})

// --- Criação ----------------------------------------------------------------
const createOpen = ref(false)
const newName = ref('')
const selectedIds = ref<string[]>([])

const MIN_PARTICIPANTS = 2
const MAX_PARTICIPANTS = 4

const canCreate = computed(
  () =>
    newName.value.trim().length >= 2 &&
    selectedIds.value.length >= MIN_PARTICIPANTS &&
    selectedIds.value.length <= MAX_PARTICIPANTS,
)

function toggleParticipant(id: string) {
  if (selectedIds.value.includes(id)) {
    selectedIds.value = selectedIds.value.filter((x) => x !== id)
  } else if (selectedIds.value.length < MAX_PARTICIPANTS) {
    selectedIds.value = [...selectedIds.value, id]
  }
}

function openCreate() {
  newName.value = ''
  selectedIds.value = []
  createOpen.value = true
}

function submitCreate() {
  if (!canCreate.value) return
  createEvent(newName.value, selectedIds.value)
  createOpen.value = false
}

// --- Visualização -----------------------------------------------------------
const viewOpen = ref(false)
const viewedEvent = ref<VotingEvent | null>(null)

function openView(event: VotingEvent) {
  viewedEvent.value = event
  viewOpen.value = true
}
</script>

<template>
  <AdminShell title="Eventos" :back-to="ADMIN_HOME_PATH">
    <div class="mb-5 flex items-center justify-between gap-4">
      <p class="text-sm text-muted">{{ events.length }} evento(s)</p>
      <AppButton @click="openCreate">+ Novo evento</AppButton>
    </div>

    <ul class="flex flex-col gap-3">
      <li
        v-for="event in events"
        :key="event.id"
        class="flex flex-wrap items-center justify-between gap-3 rounded-[var(--radius-card)] border border-line bg-surface p-4 shadow-sm"
      >
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-bold text-content">{{ event.name }}</span>
            <span
              class="rounded-full px-2 py-0.5 text-xs font-bold uppercase tracking-wide"
              :class="
                event.status === 'open'
                  ? 'bg-primary/15 text-primary'
                  : 'bg-surface-muted text-muted'
              "
            >
              {{ event.status === 'open' ? 'Aberto' : 'Encerrado' }}
            </span>
          </div>
          <p class="mt-1 text-sm text-muted">
            {{ event.participants.length }} participantes ·
            {{ nf.format(totalVotes(event)) }} votos
            <template v-if="event.closedAt">
              · encerrado em {{ df.format(new Date(event.closedAt)) }}
            </template>
          </p>
        </div>

        <div class="flex shrink-0 gap-2">
          <AppButton variant="ghost" @click="openView(event)">Visualizar</AppButton>
          <AppButton v-if="event.status === 'open'" @click="closeEvent(event.id)">
            Encerrar
          </AppButton>
        </div>
      </li>
    </ul>

    <!-- Modal: criar evento -->
    <BaseModal v-model="createOpen" title="Novo evento">
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-1.5">
          <label for="e-name" class="text-sm font-semibold text-content">Nome do evento</label>
          <input
            id="e-name"
            v-model="newName"
            type="text"
            placeholder="Ex.: Paredão #6"
            class="rounded-[var(--radius-control)] border border-line bg-surface-muted px-3 py-2.5 text-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/40"
          />
        </div>

        <div class="flex flex-col gap-2">
          <span class="text-sm font-semibold text-content">
            Participantes
            <span class="font-normal text-muted">
              (selecione de {{ MIN_PARTICIPANTS }} a {{ MAX_PARTICIPANTS }} —
              {{ selectedIds.length }} selecionado(s))
            </span>
          </span>

          <ul class="grid max-h-56 gap-2 overflow-y-auto pr-1 sm:grid-cols-2">
            <li v-for="p in participants" :key="p.id">
              <button
                type="button"
                :aria-pressed="selectedIds.includes(p.id)"
                :disabled="!selectedIds.includes(p.id) && selectedIds.length >= MAX_PARTICIPANTS"
                class="flex w-full items-center gap-2 rounded-[var(--radius-control)] border p-2 text-left transition disabled:cursor-not-allowed disabled:opacity-40"
                :class="
                  selectedIds.includes(p.id)
                    ? 'border-primary bg-primary/10'
                    : 'border-line bg-surface-muted hover:border-primary'
                "
                @click="toggleParticipant(p.id)"
              >
                <Avatar :variant="p.avatar" :size="28" class="text-primary" decorative />
                <span class="truncate text-sm font-semibold text-content">{{ p.name }}</span>
              </button>
            </li>
          </ul>
        </div>
      </div>

      <template #footer>
        <AppButton variant="ghost" @click="createOpen = false">Cancelar</AppButton>
        <AppButton :disabled="!canCreate" @click="submitCreate">Criar evento</AppButton>
      </template>
    </BaseModal>

    <!-- Modal: visualizar evento -->
    <BaseModal v-model="viewOpen" :title="viewedEvent?.name">
      <template v-if="viewedEvent">
        <p class="mb-4 text-sm text-muted">
          {{ viewedEvent.status === 'open' ? 'Aberto' : 'Encerrado' }}
          <template v-if="viewedEvent.closedAt">
            · encerrado em {{ df.format(new Date(viewedEvent.closedAt)) }}
          </template>
        </p>
        <EventVotes :event="viewedEvent" />
      </template>
      <template #footer>
        <AppButton @click="viewOpen = false">Fechar</AppButton>
      </template>
    </BaseModal>
  </AdminShell>
</template>
