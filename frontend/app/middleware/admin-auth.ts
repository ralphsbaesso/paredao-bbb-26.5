/**
 * Protege as rotas da área administrativa.
 *
 * Sem credencial → redireciona para o login. Com credencial, valida-a contra o
 * backend (`GET /admin/profile`); se o backend responder 401 (token expirado ou
 * inválido), limpa a credencial local e redireciona para o login. A rota
 * "secreta" é só ofuscação — a proteção real é a validação do token no backend.
 */
export default defineNuxtRouteMiddleware(async () => {
  const { token, fetchProfile, clear } = useAuth()

  if (!token.value) {
    return navigateTo(ADMIN_LOGIN_PATH)
  }

  try {
    await fetchProfile()
  } catch (error: unknown) {
    const status =
      (error as { statusCode?: number })?.statusCode ??
      (error as { response?: { status?: number } })?.response?.status

    if (status === 401) {
      clear()
      return navigateTo(ADMIN_LOGIN_PATH)
    }
    // Outros erros (rede/backend fora): não desloga; deixa a tela lidar.
  }
})
