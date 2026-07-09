/**
 * Validações de formulário no cliente (ver docs/tasks/008-pages.md).
 *
 * Mantidas puras e sem dependência de framework para poderem ser reutilizadas
 * por qualquer tela. Nesta fase (008) não há chamada de API — a validação é
 * apenas de UX no navegador.
 */

// Regex pragmática de e-mail: exige `algo@algo.tld` sem espaços. Não pretende
// cobrir toda a RFC 5322 — só barrar erros óbvios antes de habilitar o envio.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/** true quando `value` parece um endereço de e-mail válido. */
export function isValidEmail(value: string): boolean {
  return EMAIL_RE.test(value.trim())
}
