<script setup lang="ts">
/**
 * Casca comum das telas administrativas (ver docs/tasks/008-pages.md).
 *
 * Cabeçalho padronizado com título, e-mail do admin logado, link opcional de
 * "voltar" e botão de sair. As telas de gestão preenchem o conteúdo via slot.
 */
withDefaults(
  defineProps<{
    title: string
    backTo?: string
  }>(),
  { backTo: '' },
)

const { adminUser, logout } = useAuth()
const loggingOut = ref(false)

async function onLogout() {
  loggingOut.value = true
  try {
    await logout()
    await navigateTo(ADMIN_LOGIN_PATH, { replace: true })
  } finally {
    loggingOut.value = false
  }
}
</script>

<template>
  <div class="mx-auto flex min-h-screen max-w-4xl flex-col p-6">
    <header
      class="flex flex-wrap items-center justify-between gap-4 border-b border-line pb-5"
    >
      <div class="min-w-0">
        <NuxtLink
          v-if="backTo"
          :to="backTo"
          class="mb-1 inline-flex items-center gap-1 text-sm font-semibold text-muted transition hover:text-content"
        >
          ← Voltar
        </NuxtLink>
        <h1 class="text-2xl font-extrabold text-content">{{ title }}</h1>
        <p v-if="adminUser" class="mt-1 truncate text-sm text-muted">
          {{ adminUser.email_address }}
        </p>
      </div>
      <AppButton variant="ghost" :loading="loggingOut" @click="onLogout">
        Sair
      </AppButton>
    </header>

    <main class="flex-1 pt-6">
      <slot />
    </main>
  </div>
</template>
