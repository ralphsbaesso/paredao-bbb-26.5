<script setup lang="ts">
/**
 * `/admin/participants` — Gestão de participantes (ver docs/tasks/008-pages.md).
 *
 * Aqui o administrador APENAS cadastra participantes (sem editar/remover, por
 * escopo da atividade). Lista os já cadastrados e oferece um formulário de
 * cadastro com escolha de avatar. Dados vindos do backend (API autenticada).
 */
import { AVATAR_VARIANTS, FALLBACK_VARIANT } from '~/utils/avatars'

definePageMeta({ layout: 'admin', middleware: 'admin-auth' })

const { loadParticipants, addParticipant } = useVotingData()
const { participants, pending, error, refresh } = loadParticipants()

function suggestAvatar(): string {
  const used = new Set(participants.value.map((p) => p.avatar))
  return AVATAR_VARIANTS.find((v) => !used.has(v)) ?? FALLBACK_VARIANT
}

const name = ref('')
const avatar = ref(suggestAvatar())
const justAdded = ref<string | null>(null)
const submitting = ref(false)
const formError = ref<string | null>(null)

const canSubmit = computed(() => name.value.trim().length >= 2)

async function onSubmit() {
  if (!canSubmit.value || submitting.value) return
  submitting.value = true
  formError.value = null
  try {
    const created = await addParticipant(name.value, avatar.value)
    await refresh()
    justAdded.value = created.name
    name.value = ''
    avatar.value = suggestAvatar()
  } catch (e: unknown) {
    const data = (e as { data?: { errors?: string[] } })?.data
    formError.value = data?.errors?.[0] ?? 'Não foi possível cadastrar o participante.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <AdminShell title="Participantes" :back-to="ADMIN_HOME_PATH">
    <div class="grid gap-6 lg:grid-cols-[1fr_1.2fr]">
      <!-- Formulário de cadastro -->
      <section
        class="rounded-[var(--radius-card)] border border-line bg-surface p-6 shadow-sm"
      >
        <h2 class="mb-4 text-lg font-bold text-content">Cadastrar participante</h2>

        <form class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label for="p-name" class="text-sm font-semibold text-content">Nome</label>
            <input
              id="p-name"
              v-model="name"
              type="text"
              placeholder="Nome do participante"
              class="rounded-[var(--radius-control)] border border-line bg-surface-muted px-3 py-2.5 text-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/40"
            />
          </div>

          <div class="flex flex-col gap-2">
            <span class="text-sm font-semibold text-content">Avatar</span>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="variant in AVATAR_VARIANTS"
                :key="variant"
                type="button"
                :aria-pressed="avatar === variant"
                :title="variant"
                class="grid h-11 w-11 place-items-center rounded-[var(--radius-control)] border transition"
                :class="
                  avatar === variant
                    ? 'border-primary bg-primary/10 text-primary'
                    : 'border-line bg-surface-muted text-content hover:border-primary'
                "
                @click="avatar = variant"
              >
                <Avatar :variant="variant" :size="30" decorative />
              </button>
            </div>
          </div>

          <AppButton type="submit" :disabled="!canSubmit || submitting" class="mt-1 w-full">
            {{ submitting ? 'Cadastrando…' : 'Cadastrar' }}
          </AppButton>

          <p
            v-if="formError"
            role="alert"
            class="rounded-[var(--radius-control)] bg-red-500/10 px-3 py-2 text-sm font-medium text-red-500"
          >
            {{ formError }}
          </p>

          <p
            v-else-if="justAdded"
            role="status"
            aria-live="polite"
            class="rounded-[var(--radius-control)] bg-primary/10 px-3 py-2 text-sm font-medium text-primary"
          >
            “{{ justAdded }}” cadastrado com sucesso.
          </p>
        </form>
      </section>

      <!-- Lista -->
      <section>
        <h2 class="mb-4 text-lg font-bold text-content">
          Cadastrados
          <span class="text-sm font-semibold text-muted">({{ participants.length }})</span>
        </h2>

        <div v-if="pending" class="text-sm text-muted">Carregando participantes…</div>
        <div v-else-if="error" class="text-sm">
          <p class="text-content">Não foi possível carregar os participantes.</p>
          <AppButton class="mt-2" variant="ghost" @click="refresh()">Tentar novamente</AppButton>
        </div>
        <p v-else-if="!participants.length" class="text-sm text-muted">
          Nenhum participante cadastrado ainda.
        </p>
        <ul v-else class="grid gap-3 sm:grid-cols-2">
          <li
            v-for="p in participants"
            :key="p.id"
            class="flex items-center gap-3 rounded-[var(--radius-card)] border border-line bg-surface p-3"
          >
            <Avatar :variant="p.avatar" :size="40" class="text-primary" decorative />
            <span class="truncate font-semibold text-content">{{ p.name }}</span>
          </li>
        </ul>
      </section>
    </div>
  </AdminShell>
</template>
