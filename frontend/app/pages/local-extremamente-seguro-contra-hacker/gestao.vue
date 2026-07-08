<script setup lang="ts">
/**
 * Área de gestão (dashboard administrativo).
 *
 * Protegida pelo middleware `admin-auth`: acesso sem credencial válida (ou com
 * 401 do backend) redireciona para o login. Tema dark, sem anúncios. As telas
 * de gestão reais (paredões, participantes, relatórios) nascerão aqui.
 */
definePageMeta({ layout: 'admin', middleware: 'admin-auth' })

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
      <div>
        <h1 class="text-2xl font-extrabold text-content">Área de gestão</h1>
        <p v-if="adminUser" class="mt-1 text-sm text-muted">
          {{ adminUser.email_address }}
        </p>
      </div>
      <AppButton variant="ghost" :loading="loggingOut" @click="onLogout">
        Sair
      </AppButton>
    </header>

    <main class="flex flex-1 flex-col items-center justify-center gap-2 text-center">
      <p class="text-lg font-semibold text-content">Você está autenticado.</p>
      <p class="max-w-md text-sm text-muted">
        As telas de gestão (paredões, participantes e relatórios) serão
        adicionadas aqui.
      </p>
    </main>
  </div>
</template>
