/** Cliente HTTP compartilhado: base da API (SSR vs. browser) + token Bearer. */
export function useApi() {
  const config = useRuntimeConfig()
  const token = useCookie<string | null>('admin_session_token', { default: () => null })

  function apiUrl(path: string): string {
    // No SSR alcança a API pela rede interna do Compose; no browser, a base pública.
    const base = import.meta.server
      ? config.apiBaseInternal || config.public.apiBase
      : config.public.apiBase
    return `${base}${path}`
  }

  function authHeaders(): Record<string, string> {
    return token.value ? { Authorization: `Bearer ${token.value}` } : {}
  }

  type FetchOpts = Parameters<typeof $fetch>[1]

  function publicFetch<T>(path: string, opts: FetchOpts = {}): Promise<T> {
    return $fetch<T>(apiUrl(path), opts)
  }

  function adminFetch<T>(path: string, opts: FetchOpts = {}): Promise<T> {
    return $fetch<T>(apiUrl(path), {
      ...opts,
      headers: { ...authHeaders(), ...(opts?.headers as Record<string, string> | undefined) },
    })
  }

  return { apiUrl, authHeaders, publicFetch, adminFetch }
}
