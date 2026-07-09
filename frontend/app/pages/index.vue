<script setup lang="ts">
/**
 * `/` — Apresentação do programa (ver docs/tasks/008-pages.md).
 *
 * Área pública (layout default: tema light + rodapé de anúncios). Traz a
 * apresentação do Paredão BBB 26.5 e UM ÚNICO botão que leva à votação.
 */
useHead({ title: 'Paredão BBB 26.5' })
</script>

<template>
  <main class="flex min-h-full flex-col items-center justify-center gap-6 px-6 py-16 text-center">
    <span
      class="rounded-full bg-surface-muted px-4 py-1 text-sm font-semibold uppercase tracking-wide text-primary ring-1 ring-line"
    >
      Ao vivo · 26.5
    </span>

    <h1 class="max-w-2xl text-4xl font-extrabold tracking-tight text-content sm:text-5xl">
      Paredão <span class="text-primary">BBB 26.5</span>
    </h1>

    <p class="max-w-xl text-lg text-muted">
      A decisão está nas suas mãos. Vote em quem deve continuar no jogo e
      acompanhe o resultado em tempo real. É rápido, é grátis e cada voto conta.
    </p>

    <AppButton class="mt-2 px-8 py-3 text-lg" @click="navigateTo('/votacao')">
      Quero votar
    </AppButton>
  </main>
</template>
