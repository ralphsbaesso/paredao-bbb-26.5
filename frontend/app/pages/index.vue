<script setup lang="ts">
// URL da API vem de runtimeConfig.public (env NUXT_PUBLIC_API_BASE em runtime).
const apiBase = useRuntimeConfig().public.apiBase || '(não configurada)'
</script>

<template>
  <main class="flex min-h-full flex-col items-center justify-center gap-4 p-8 text-center">
    <h1 class="text-4xl font-bold tracking-tight text-primary">
      Paredão BBB 26.5
    </h1>
    <p class="text-lg text-muted">
      Setup do frontend concluído — Nuxt 4 + Tailwind CSS 4 (SSR).
    </p>
    <span
      class="rounded-full bg-surface-muted px-4 py-1 text-sm font-medium text-content ring-1 ring-line"
    >
      API base: {{ apiBase }}
    </span>
  </main>
</template>
