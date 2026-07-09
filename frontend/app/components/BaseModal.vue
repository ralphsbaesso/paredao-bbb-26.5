<script setup lang="ts">
/**
 * Modal base reutilizável (ver docs/tasks/008-pages.md).
 *
 * Controlado por `v-model` (open). Renderiza um backdrop com o cartão centralizado
 * e emite `close` ao clicar fora, pressionar Esc ou clicar no "x". Acessível:
 * `role="dialog"` + `aria-modal`, foco inicial no cartão e travamento do scroll
 * do body enquanto aberto. Segue os tokens de estilo centralizados (003).
 */
const open = defineModel<boolean>({ default: false })

withDefaults(defineProps<{ title?: string }>(), { title: '' })

const emit = defineEmits<{ close: [] }>()

const card = ref<HTMLElement | null>(null)

function close() {
  open.value = false
  emit('close')
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') close()
}

// Trava o scroll do body e liga o Esc apenas enquanto o modal está aberto.
watch(
  open,
  (isOpen) => {
    if (!import.meta.client) return
    if (isOpen) {
      document.addEventListener('keydown', onKeydown)
      document.body.style.overflow = 'hidden'
      nextTick(() => card.value?.focus())
    } else {
      document.removeEventListener('keydown', onKeydown)
      document.body.style.overflow = ''
    }
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  if (!import.meta.client) return
  document.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="open"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm"
        @click.self="close"
      >
        <section
          ref="card"
          tabindex="-1"
          role="dialog"
          aria-modal="true"
          :aria-label="title || undefined"
          class="w-full max-w-md rounded-[var(--radius-card)] border border-line bg-surface p-6 shadow-2xl outline-none"
        >
          <header v-if="title || $slots.header" class="mb-4 flex items-start justify-between gap-4">
            <slot name="header">
              <h2 class="text-xl font-extrabold text-content">{{ title }}</h2>
            </slot>
            <button
              type="button"
              aria-label="Fechar"
              class="grid h-8 w-8 shrink-0 place-items-center rounded-full text-muted transition hover:bg-surface-muted hover:text-content"
              @click="close"
            >
              <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                <path d="M6 6l12 12M18 6L6 18" />
              </svg>
            </button>
          </header>

          <slot />

          <footer v-if="$slots.footer" class="mt-6 flex flex-wrap justify-end gap-3">
            <slot name="footer" />
          </footer>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 160ms ease;
}
.modal-enter-active section,
.modal-leave-active section {
  transition: transform 160ms ease, opacity 160ms ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from section,
.modal-leave-to section {
  transform: translateY(12px) scale(0.98);
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .modal-enter-active,
  .modal-leave-active,
  .modal-enter-active section,
  .modal-leave-active section {
    transition-duration: 1ms;
  }
  .modal-enter-from section,
  .modal-leave-to section {
    transform: none;
  }
}
</style>
