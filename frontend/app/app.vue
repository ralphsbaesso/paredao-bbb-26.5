<script setup lang="ts">
// URL da API vem de runtimeConfig.public (env NUXT_PUBLIC_API_BASE em runtime).
const apiBase = useRuntimeConfig().public.apiBase || '(não configurada)'
</script>

<template>
  <main class="flex min-h-screen flex-col items-center justify-center gap-4 bg-slate-950 p-8 text-center">
    <h1 class="text-4xl font-bold tracking-tight text-emerald-400">
      Paredão BBB 26.5
    </h1>
    <p class="text-lg text-slate-300">
      Setup do frontend concluído — Nuxt 4 + Tailwind CSS 4 (SSR).
    </p>
    <span class="rounded-full bg-emerald-500/10 px-4 py-1 text-sm font-medium text-emerald-300 ring-1 ring-emerald-500/30">
      API base: {{ apiBase }}
    </span>
  </main>
</template>
