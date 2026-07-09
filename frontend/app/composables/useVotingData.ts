/**
 * Fonte de dados MOCKADA do paredão (ver docs/tasks/008-pages.md).
 *
 * Esta atividade (008) NÃO integra com o backend: todas as telas trabalham com
 * dados estáticos, mantidos em memória. Ainda assim o estado é reativo e
 * compartilhado (via `useState`), então as ações do administrador (criar/encerrar
 * evento, cadastrar participante) e os votos do público refletem imediatamente
 * nas demais telas dentro da mesma sessão de navegação. A conexão real com a API
 * substituirá este composable em atividade posterior.
 *
 * Domínios (ver 008):
 *   - Event       → evento/paredão de votação (aberto ou encerrado).
 *   - Participant → participante que recebe votos.
 */

import { AVATAR_VARIANTS, FALLBACK_VARIANT } from '~/utils/avatars'

export interface Participant {
  id: string
  name: string
  /** Nome da variante de avatar (vocabulário compartilhado — ver 005-avatars). */
  avatar: string
}

export interface VotingEvent {
  id: string
  name: string
  status: 'open' | 'closed'
  participants: Participant[]
  /** Contagem de votos por id de participante. */
  votes: Record<string, number>
  createdAt: string
  /** Data de encerramento (ISO) — null enquanto o evento estiver aberto. */
  closedAt: string | null
}

// --- Semente estática (ids fixos p/ estabilidade no SSR) --------------------

const SEED_PARTICIPANTS: Participant[] = [
  { id: 'p1', name: 'Ana Prado', avatar: 'sun' },
  { id: 'p2', name: 'Bruno Lemos', avatar: 'storm' },
  { id: 'p3', name: 'Carla Dias', avatar: 'wave' },
  { id: 'p4', name: 'Diego Rocha', avatar: 'ember' },
  { id: 'p5', name: 'Elisa Moura', avatar: 'blossom' },
  { id: 'p6', name: 'Felipe Nunes', avatar: 'comet' },
]

function participant(id: string): Participant {
  return SEED_PARTICIPANTS.find((p) => p.id === id)!
}

const SEED_EVENTS: VotingEvent[] = [
  {
    id: 'e1',
    name: 'Paredão #5',
    status: 'open',
    participants: [participant('p1'), participant('p2'), participant('p3')],
    votes: { p1: 0, p2: 0, p3: 0 },
    createdAt: '2026-07-08T20:00:00.000Z',
    closedAt: null,
  },
  {
    id: 'e2',
    name: 'Paredão #4',
    status: 'closed',
    participants: [participant('p4'), participant('p5')],
    votes: { p4: 128_540, p5: 342_910 },
    createdAt: '2026-07-01T20:00:00.000Z',
    closedAt: '2026-07-03T23:00:00.000Z',
  },
  {
    id: 'e3',
    name: 'Paredão #3',
    status: 'closed',
    participants: [participant('p6'), participant('p1'), participant('p4')],
    votes: { p6: 51_002, p1: 77_431, p4: 210_887 },
    createdAt: '2026-06-24T20:00:00.000Z',
    closedAt: '2026-06-26T23:00:00.000Z',
  },
]

// Clona a semente para não mutar as constantes do módulo (compartilhadas entre
// requisições no servidor).
function seedParticipants(): Participant[] {
  return SEED_PARTICIPANTS.map((p) => ({ ...p }))
}
function seedEvents(): VotingEvent[] {
  return SEED_EVENTS.map((e) => ({
    ...e,
    participants: [...e.participants],
    votes: { ...e.votes },
  }))
}

let idCounter = 0
function nextId(prefix: string): string {
  idCounter += 1
  // Prefixo + contador + timestamp: só é chamado em ações do cliente, então não
  // há risco de divergência de hidratação com o SSR.
  return `${prefix}${idCounter}-${Date.now()}`
}

export function useVotingData() {
  const participants = useState<Participant[]>('voting:participants', seedParticipants)
  const events = useState<VotingEvent[]>('voting:events', seedEvents)

  // O evento "atual" é o único aberto; os demais são votações anteriores.
  const currentEvent = computed(() => events.value.find((e) => e.status === 'open') ?? null)
  const closedEvents = computed(() =>
    events.value
      .filter((e) => e.status === 'closed')
      .sort((a, b) => (b.closedAt ?? '').localeCompare(a.closedAt ?? '')),
  )

  /** Soma dos votos de um evento. */
  function totalVotes(event: VotingEvent): number {
    return Object.values(event.votes).reduce((sum, n) => sum + n, 0)
  }

  /** Percentual de votos de um participante (0–100), robusto a total zero. */
  function votePercent(event: VotingEvent, participantId: string): number {
    const total = totalVotes(event)
    if (total === 0) return 0
    return Math.round(((event.votes[participantId] ?? 0) / total) * 100)
  }

  /** Próxima variante de avatar ainda não usada (só p/ mock de cadastro). */
  function suggestAvatar(): string {
    const used = new Set(participants.value.map((p) => p.avatar))
    return AVATAR_VARIANTS.find((v) => !used.has(v)) ?? FALLBACK_VARIANT
  }

  // --- Ações do administrador ---------------------------------------------

  function addParticipant(name: string, avatar?: string): Participant {
    const created: Participant = {
      id: nextId('p'),
      name: name.trim(),
      avatar: avatar ?? suggestAvatar(),
    }
    participants.value = [...participants.value, created]
    return created
  }

  function createEvent(name: string, participantIds: string[]): VotingEvent {
    const chosen = participants.value.filter((p) => participantIds.includes(p.id))
    const created: VotingEvent = {
      id: nextId('e'),
      name: name.trim(),
      status: 'open',
      participants: chosen,
      votes: Object.fromEntries(chosen.map((p) => [p.id, 0])),
      createdAt: new Date().toISOString(),
      closedAt: null,
    }
    events.value = [created, ...events.value]
    return created
  }

  function closeEvent(id: string): void {
    events.value = events.value.map((e) =>
      e.id === id && e.status === 'open'
        ? { ...e, status: 'closed', closedAt: new Date().toISOString() }
        : e,
    )
  }

  // --- Ação do público -----------------------------------------------------

  /** Registra um voto (mock) para um participante do evento aberto. */
  function addVote(eventId: string, participantId: string): void {
    events.value = events.value.map((e) => {
      if (e.id !== eventId || e.status !== 'open') return e
      return { ...e, votes: { ...e.votes, [participantId]: (e.votes[participantId] ?? 0) + 1 } }
    })
  }

  function getEvent(id: string): VotingEvent | null {
    return events.value.find((e) => e.id === id) ?? null
  }

  return {
    participants,
    events,
    currentEvent,
    closedEvents,
    totalVotes,
    votePercent,
    suggestAvatar,
    addParticipant,
    createEvent,
    closeEvent,
    addVote,
    getEvent,
  }
}
