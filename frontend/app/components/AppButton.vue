<script setup lang="ts">
/**
 * Botão padronizado e animado (diretriz da 003).
 * Suporta estado de carregamento, que também bloqueia o clique — evitando
 * envios duplicados enquanto uma ação assíncrona está em andamento.
 */
withDefaults(
  defineProps<{
    type?: 'button' | 'submit'
    variant?: 'primary' | 'ghost'
    loading?: boolean
    disabled?: boolean
  }>(),
  {
    type: 'button',
    variant: 'primary',
    loading: false,
    disabled: false,
  },
)
</script>

<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :aria-busy="loading"
    class="btn"
    :class="variant === 'primary' ? 'btn-primary' : 'btn-ghost'"
  >
    <span v-if="loading" class="btn-spinner" aria-hidden="true" />
    <slot />
  </button>
</template>
