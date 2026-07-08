/**
 * Avatares vetoriais (rostos estilo emoji) — dados e composição do SVG.
 *
 * Cada participante do paredão é representado por uma VARIANTE nomeada. O nome é
 * o vocabulário estável compartilhado entre backend e frontend (ver
 * docs/tasks/005-avatars.md): o backend envia o nome, o frontend resolve o rosto.
 *
 * Um rosto é montado a partir de traços simples (formato, olhos, boca, e opcionais
 * sobrancelha/bochecha). Toda a arte é line-art monocromática em `currentColor`,
 * então herda a cor do contexto (tokens `--bbb-*`) e funciona nos temas light e
 * dark sem valores hardcoded. O viewBox é fixo em 0 0 64 64.
 */

type Face = 'round' | 'oval' | 'wide' | 'square'
type Eyes =
  | 'dot'
  | 'round'
  | 'happy'
  | 'wink'
  | 'closed'
  | 'sleepy'
  | 'star'
  | 'wide'
  | 'squint'
  | 'surprised'
type Mouth =
  | 'smile'
  | 'grin'
  | 'open'
  | 'flat'
  | 'frown'
  | 'small'
  | 'cat'
  | 'tongue'
  | 'smirk'
  | 'teeth'
  | 'wavy'
type Brow = 'raised' | 'flat'

interface AvatarSpec {
  face: Face
  eyes: Eyes
  mouth: Mouth
  brow?: Brow
  cheek?: boolean
}

const STROKE = 'fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"'

function faceSvg(face: Face): string {
  switch (face) {
    case 'oval':
      return `<ellipse cx="32" cy="32" rx="22" ry="27" ${STROKE}/>`
    case 'wide':
      return `<ellipse cx="32" cy="33" rx="27" ry="22" ${STROKE}/>`
    case 'square':
      return `<rect x="8" y="8" width="48" height="48" rx="16" ${STROKE}/>`
    case 'round':
    default:
      return `<circle cx="32" cy="32" r="26" ${STROKE}/>`
  }
}

function eyesSvg(eyes: Eyes): string {
  switch (eyes) {
    case 'round':
      return (
        `<circle cx="23" cy="27" r="4" ${STROKE}/><circle cx="41" cy="27" r="4" ${STROKE}/>` +
        `<circle cx="23" cy="27" r="1.6" fill="currentColor"/><circle cx="41" cy="27" r="1.6" fill="currentColor"/>`
      )
    case 'happy':
      return `<path d="M19 29 Q23 23 27 29" ${STROKE}/><path d="M37 29 Q41 23 45 29" ${STROKE}/>`
    case 'wink':
      return `<path d="M19 29 Q23 23 27 29" ${STROKE}/><circle cx="41" cy="27" r="2.6" fill="currentColor"/>`
    case 'closed':
      return `<path d="M19 27 h8" ${STROKE}/><path d="M37 27 h8" ${STROKE}/>`
    case 'sleepy':
      return `<path d="M19 26 Q23 30 27 26" ${STROKE}/><path d="M37 26 Q41 30 45 26" ${STROKE}/>`
    case 'star':
      return (
        `<path d="M23 23 v8 M19 27 h8" ${STROKE}/>` +
        `<path d="M41 23 v8 M37 27 h8" ${STROKE}/>`
      )
    case 'wide':
      return (
        `<circle cx="23" cy="27" r="5" ${STROKE}/><circle cx="41" cy="27" r="5" ${STROKE}/>` +
        `<circle cx="23" cy="27" r="2" fill="currentColor"/><circle cx="41" cy="27" r="2" fill="currentColor"/>`
      )
    case 'squint':
      return `<path d="M20 26 l6 2" ${STROKE}/><path d="M44 26 l-6 2" ${STROKE}/>`
    case 'surprised':
      return `<circle cx="23" cy="27" r="4" ${STROKE}/><circle cx="41" cy="27" r="4" ${STROKE}/>`
    case 'dot':
    default:
      return `<circle cx="23" cy="27" r="2.6" fill="currentColor"/><circle cx="41" cy="27" r="2.6" fill="currentColor"/>`
  }
}

function mouthSvg(mouth: Mouth): string {
  switch (mouth) {
    case 'grin':
      return `<path d="M22 40 Q32 53 42 40 Z" fill="currentColor"/>`
    case 'open':
      return `<ellipse cx="32" cy="44" rx="7" ry="6" fill="currentColor"/>`
    case 'flat':
      return `<path d="M24 44 h16" ${STROKE}/>`
    case 'frown':
      return `<path d="M22 48 Q32 40 42 48" ${STROKE}/>`
    case 'small':
      return `<circle cx="32" cy="45" r="3.2" fill="currentColor"/>`
    case 'cat':
      return `<path d="M23 42 Q27.5 47 32 42 Q36.5 47 41 42" ${STROKE}/>`
    case 'tongue':
      return `<path d="M22 41 Q32 50 42 41" ${STROKE}/><rect x="29" y="45" width="6" height="6" rx="3" fill="currentColor"/>`
    case 'smirk':
      return `<path d="M25 45 Q33 50 40 42" ${STROKE}/>`
    case 'teeth':
      return `<rect x="24" y="40" width="16" height="8" rx="3" ${STROKE}/><path d="M32 40 v8" ${STROKE}/>`
    case 'wavy':
      return `<path d="M24 44 Q28 40 32 44 Q36 48 40 44" ${STROKE}/>`
    case 'smile':
    default:
      return `<path d="M22 41 Q32 50 42 41" ${STROKE}/>`
  }
}

function browSvg(brow?: Brow): string {
  switch (brow) {
    case 'raised':
      return `<path d="M19 20 Q23 17 27 20" ${STROKE}/><path d="M37 20 Q41 17 45 20" ${STROKE}/>`
    case 'flat':
      return `<path d="M19 20 h8" ${STROKE}/><path d="M37 20 h8" ${STROKE}/>`
    default:
      return ''
  }
}

function cheekSvg(cheek?: boolean): string {
  if (!cheek) return ''
  return `<circle cx="17" cy="38" r="3" fill="currentColor" opacity="0.3"/><circle cx="47" cy="38" r="3" fill="currentColor" opacity="0.3"/>`
}

function composeSpec(spec: AvatarSpec): string {
  return (
    faceSvg(spec.face) +
    cheekSvg(spec.cheek) +
    browSvg(spec.brow) +
    eyesSvg(spec.eyes) +
    mouthSvg(spec.mouth)
  )
}

/**
 * As 30 variantes distintas. Os nomes formam o vocabulário estável (temático)
 * compartilhado com o backend. NÃO renomear sem alinhar com o backend.
 */
export const AVATAR_SPECS: Record<string, AvatarSpec> = {
  sun: { face: 'round', eyes: 'happy', mouth: 'grin', cheek: true },
  moon: { face: 'oval', eyes: 'sleepy', mouth: 'smirk' },
  star: { face: 'round', eyes: 'star', mouth: 'open' },
  cloud: { face: 'wide', eyes: 'dot', mouth: 'flat' },
  rain: { face: 'oval', eyes: 'sleepy', mouth: 'frown' },
  storm: { face: 'square', eyes: 'squint', mouth: 'teeth', brow: 'flat' },
  snow: { face: 'round', eyes: 'surprised', mouth: 'small', cheek: true },
  wind: { face: 'wide', eyes: 'closed', mouth: 'wavy' },
  rainbow: { face: 'round', eyes: 'happy', mouth: 'smile', brow: 'raised', cheek: true },
  comet: { face: 'oval', eyes: 'wink', mouth: 'smirk' },
  planet: { face: 'wide', eyes: 'round', mouth: 'open' },
  meteor: { face: 'square', eyes: 'squint', mouth: 'grin' },
  dawn: { face: 'round', eyes: 'happy', mouth: 'smile', cheek: true },
  dusk: { face: 'oval', eyes: 'sleepy', mouth: 'flat' },
  spark: { face: 'round', eyes: 'star', mouth: 'grin' },
  ember: { face: 'square', eyes: 'dot', mouth: 'smirk' },
  frost: { face: 'round', eyes: 'surprised', mouth: 'small' },
  breeze: { face: 'wide', eyes: 'closed', mouth: 'smile' },
  tide: { face: 'oval', eyes: 'dot', mouth: 'wavy' },
  wave: { face: 'wide', eyes: 'happy', mouth: 'cat' },
  coral: { face: 'round', eyes: 'wink', mouth: 'grin', cheek: true },
  pearl: { face: 'round', eyes: 'round', mouth: 'small', cheek: true },
  dune: { face: 'wide', eyes: 'squint', mouth: 'flat' },
  mesa: { face: 'square', eyes: 'closed', mouth: 'teeth' },
  canyon: { face: 'oval', eyes: 'surprised', mouth: 'open' },
  river: { face: 'round', eyes: 'sleepy', mouth: 'wavy' },
  forest: { face: 'square', eyes: 'dot', mouth: 'smile' },
  meadow: { face: 'round', eyes: 'happy', mouth: 'tongue', cheek: true },
  blossom: { face: 'round', eyes: 'round', mouth: 'smile', brow: 'raised', cheek: true },
  harvest: { face: 'wide', eyes: 'wink', mouth: 'cat' },
}

/** Nomes de variante válidos (o vocabulário estável). */
export const AVATAR_VARIANTS = Object.keys(AVATAR_SPECS)

/** Variante usada quando o nome é ausente/desconhecido. */
export const FALLBACK_VARIANT = 'cloud'

/** true quando `name` corresponde a uma variante conhecida. */
export function isAvatarVariant(name?: string | null): boolean {
  return !!name && Object.prototype.hasOwnProperty.call(AVATAR_SPECS, name)
}

/** Resolve o nome recebido para uma variante conhecida (ou o fallback). */
export function resolveAvatarVariant(name?: string | null): string {
  return isAvatarVariant(name) ? (name as string) : FALLBACK_VARIANT
}

/** Markup interno (<circle>/<path>/…) do SVG para o nome recebido. */
export function avatarInnerSvg(name?: string | null): string {
  return composeSpec(AVATAR_SPECS[resolveAvatarVariant(name)]!)
}
