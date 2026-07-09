/**
 * Autenticação do administrador (frontend).
 *
 * Consome os endpoints API-only do backend (ver docs/tasks/002-authentication.md):
 *   POST   /admin/session   → login, devolve { token, expires_at, admin_user }
 *   DELETE /admin/session   → logout, invalida o token (Bearer)
 *   GET    /admin/profile   → valida o token atual (200) ou 401
 *
 * A credencial (token de sessão) é guardada num cookie, o que a torna acessível
 * também no SSR — permitindo que o middleware de rota valide o acesso no
 * servidor. Nas chamadas autenticadas ela é reenviada no header `Authorization`.
 */

export interface AdminUser {
  id: number
  email_address: string
}

interface SessionPayload {
  token: string
  expires_at: string
  admin_user: AdminUser
}

// Rotas da área administrativa (ver docs/tasks/004-login-admin.md e 008-pages.md).
export const ADMIN_BASE_PATH = '/local-extremamente-seguro-contra-hacker/admin'
export const ADMIN_LOGIN_PATH = `${ADMIN_BASE_PATH}/login`
export const ADMIN_HOME_PATH = ADMIN_BASE_PATH
export const ADMIN_EVENTS_PATH = `${ADMIN_BASE_PATH}/events`
export const ADMIN_PARTICIPANTS_PATH = `${ADMIN_BASE_PATH}/participants`

export function useAuth() {
  const config = useRuntimeConfig()

  // Fonte da verdade da credencial. maxAge alinhado ao TTL padrão do backend
  // (ADMIN_SESSION_TTL_HOURS, 24h por default).
  const token = useCookie<string | null>('admin_session_token', {
    sameSite: 'lax',
    secure: !import.meta.dev,
    maxAge: 60 * 60 * 24,
    default: () => null,
  })

  const adminUser = useState<AdminUser | null>('admin_user', () => null)
  const isAuthenticated = computed(() => Boolean(token.value))

  function apiUrl(path: string) {
    return `${config.public.apiBase}${path}`
  }

  function authHeaders(): Record<string, string> {
    return token.value ? { Authorization: `Bearer ${token.value}` } : {}
  }

  function clear() {
    token.value = null
    adminUser.value = null
  }

  async function login(emailAddress: string, password: string): Promise<SessionPayload> {
    const payload = await $fetch<SessionPayload>(apiUrl('/admin/session'), {
      method: 'POST',
      body: { email_address: emailAddress, password },
    })
    token.value = payload.token
    adminUser.value = payload.admin_user
    return payload
  }

  async function logout(): Promise<void> {
    try {
      if (token.value) {
        await $fetch(apiUrl('/admin/session'), {
          method: 'DELETE',
          headers: authHeaders(),
        })
      }
    } catch {
      // O logout local acontece de qualquer forma no finally — mesmo que o
      // token já esteja inválido/expirado no backend.
    } finally {
      clear()
    }
  }

  /** Valida o token atual contra o backend. Lança em 401 (token inválido). */
  async function fetchProfile(): Promise<AdminUser | null> {
    if (!token.value) return null
    const profile = await $fetch<AdminUser>(apiUrl('/admin/profile'), {
      headers: authHeaders(),
    })
    adminUser.value = profile
    return profile
  }

  return {
    token,
    adminUser,
    isAuthenticated,
    login,
    logout,
    fetchProfile,
    clear,
  }
}
