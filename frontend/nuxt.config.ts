import tailwindcss from '@tailwindcss/vite'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2026-07-06',
  devtools: { enabled: true },

  // Estilo global via Tailwind CSS v4.
  css: ['~/assets/css/main.css'],

  vite: {
    plugins: [tailwindcss()],
  },

  // SSR explícito + servidor Node (Nitro node-server) para rodar em container.
  ssr: true,
  nitro: {
    preset: 'node-server',
  },

  runtimeConfig: {
    public: {
      // Sobrescrito em runtime por NUXT_PUBLIC_API_BASE — nunca hardcoded no build.
      apiBase: '',
    },
  },
})
