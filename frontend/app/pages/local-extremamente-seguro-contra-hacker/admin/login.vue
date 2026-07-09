<script setup lang="ts">
/**
 * Tela de login do administrador (docs/tasks/004-login-admin.md, 008-pages.md).
 *
 * Única porta de entrada da área restrita: SÓ o formulário de login — sem
 * "esqueci minha senha" e sem cadastro. Rota "secreta" (ofuscação, não
 * segurança). Tema dark, sem área de anúncios.
 */
definePageMeta({ layout: 'admin' })

const { login, isAuthenticated } = useAuth()

const emailAddress = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

const canSubmit = computed(
  () => emailAddress.value.trim() !== '' && password.value !== '',
)

// Já autenticado? Não faz sentido ficar no login.
onMounted(() => {
  if (isAuthenticated.value) {
    navigateTo(ADMIN_HOME_PATH, { replace: true })
  }
})

async function onSubmit() {
  errorMessage.value = ''
  // Guarda contra envios inválidos/duplicados (o botão também bloqueia).
  if (!canSubmit.value || loading.value) return

  loading.value = true
  try {
    await login(emailAddress.value.trim(), password.value)
    await navigateTo(ADMIN_HOME_PATH, { replace: true })
  } catch (error: unknown) {
    const status =
      (error as { statusCode?: number })?.statusCode ??
      (error as { response?: { status?: number } })?.response?.status

    if (status === 429) {
      errorMessage.value =
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.'
    } else {
      // 401 e demais falhas: mensagem genérica, sem vazar o motivo
      // (não revela se o e-mail existe).
      errorMessage.value = 'Credenciais inválidas.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="flex min-h-screen items-center justify-center p-6">
    <section
      class="w-full max-w-sm rounded-[var(--radius-card)] border border-line bg-surface p-8 shadow-2xl"
    >
      <header class="mb-6 text-center">
        <h1 class="text-2xl font-extrabold text-content">Área administrativa</h1>
        <p class="mt-1 text-sm text-muted">Paredão BBB 26.5 · acesso restrito</p>
      </header>

      <form class="flex flex-col gap-4" novalidate @submit.prevent="onSubmit">
        <div class="flex flex-col gap-1.5">
          <label for="email" class="text-sm font-semibold text-content">
            E-mail
          </label>
          <input
            id="email"
            v-model="emailAddress"
            type="email"
            name="email"
            autocomplete="username"
            required
            :disabled="loading"
            class="rounded-[var(--radius-control)] border border-line bg-surface-muted px-3 py-2.5 text-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/40 disabled:opacity-60"
            placeholder="admin@exemplo.com"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <label for="password" class="text-sm font-semibold text-content">
            Senha
          </label>
          <input
            id="password"
            v-model="password"
            type="password"
            name="password"
            autocomplete="current-password"
            required
            :disabled="loading"
            class="rounded-[var(--radius-control)] border border-line bg-surface-muted px-3 py-2.5 text-content outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/40 disabled:opacity-60"
            placeholder="••••••••"
          />
        </div>

        <p
          v-if="errorMessage"
          role="alert"
          aria-live="assertive"
          class="rounded-[var(--radius-control)] bg-danger-surface px-3 py-2 text-sm font-medium text-danger"
        >
          {{ errorMessage }}
        </p>

        <AppButton
          type="submit"
          :loading="loading"
          :disabled="!canSubmit"
          class="mt-2 w-full"
        >
          {{ loading ? 'Entrando…' : 'Entrar' }}
        </AppButton>
      </form>
    </section>
  </main>
</template>
