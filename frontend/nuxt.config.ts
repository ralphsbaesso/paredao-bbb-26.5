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
    // Base usada nas chamadas SSR (servidor Nuxt → API pela rede interna do
    // Compose). Sobrescrita em runtime por NUXT_API_BASE_INTERNAL. Server-only:
    // nunca é exposta ao browser. Cai para a base pública quando não definida.
    apiBaseInternal: '',
    public: {
      // Base usada pelo browser (client-side). Sobrescrita em runtime por
      // NUXT_PUBLIC_API_BASE — nunca hardcoded no build. Precisa ser um host que
      // o navegador alcance (ex.: http://localhost:3000), não o hostname interno.
      apiBase: '',
      // URLs dos serviços de observabilidade linkados no painel admin.
      // Sobrescritas em runtime por NUXT_PUBLIC_GRAFANA_URL / _PROMETHEUS_URL.
      grafanaUrl: '',
      prometheusUrl: '',
    },
  },
})
