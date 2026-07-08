<script setup lang="ts">
// Layout público: tema light + rodapé reservado para anúncios (ver 003).
useHead({ htmlAttrs: { 'data-theme': 'light' } })
</script>

<template>
  <div class="flex min-h-screen flex-col bg-bg text-content">
    <div class="flex-1">
      <slot />
    </div>

    <!-- Área de anúncios reservada em todas as telas públicas (docs/tasks/003). -->
    <footer
      class="flex h-16 items-center justify-center border-t border-line bg-surface-muted px-4 text-center text-sm font-semibold text-muted"
    >
      anuncie aqui - telefone: 224 4000
    </footer>
  </div>
</template>
