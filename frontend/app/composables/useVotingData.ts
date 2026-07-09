/**
 * Dados de votação — integração HTTP com o backend. O contrato da API usa outros
 * nomes (`nickname`→`name`, `title`→`name`, `closed_at`→`status`, typo
 * `partcipant`); o mapeamento acontece aqui, na borda HTTP.
 */

export interface Participant {
  id: number
  name: string
  avatar: string
  eliminated: boolean
}

export interface VotingEvent {
  id: number
  name: string
  status: 'open' | 'closed'
  participants: Participant[]
  votes: Record<number, number>
  createdAt: string
  closedAt: string | null
}

interface RawParticipant {
  id: number
  nickname: string
  avatar: string
  eliminated: boolean
}

interface RawEvent {
  id: number
  title: string
  closed_at: string | null
  created_at: string
  updated_at: string
  partcipants?: RawParticipant[]
  votes?: Record<string, number>
  total_votes?: number
}

function mapParticipant(raw: RawParticipant): Participant {
  return { id: raw.id, name: raw.nickname, avatar: raw.avatar, eliminated: raw.eliminated }
}

function mapEvent(raw: RawEvent): VotingEvent {
  return {
    id: raw.id,
    name: raw.title,
    status: raw.closed_at ? 'closed' : 'open',
    participants: (raw.partcipants ?? []).map(mapParticipant),
    votes: Object.fromEntries(
      Object.entries(raw.votes ?? {}).map(([id, count]) => [Number(id), count]),
    ),
    createdAt: raw.created_at,
    closedAt: raw.closed_at,
  }
}

export function useVotingData() {
  const { publicFetch, adminFetch } = useApi()

  function loadEvents() {
    const { data, pending, error, refresh } = useAsyncData('voting:events', () =>
      publicFetch<RawEvent[]>('/events'),
    )
    const events = computed(() => (data.value ?? []).map(mapEvent))
    const currentEvent = computed(() => events.value.find((e) => e.status === 'open') ?? null)
    const closedEvents = computed(() =>
      events.value
        .filter((e) => e.status === 'closed')
        .sort((a, b) => (b.closedAt ?? '').localeCompare(a.closedAt ?? '')),
    )
    return { events, currentEvent, closedEvents, pending, error, refresh }
  }

  function loadEvent(id: number | string) {
    const { data, pending, error, refresh } = useAsyncData(`voting:event:${id}`, () =>
      publicFetch<RawEvent>(`/events/${id}`),
    )
    const event = computed(() => (data.value ? mapEvent(data.value) : null))
    return { event, pending, error, refresh }
  }

  // Rota autenticada — usar só em telas de admin.
  function loadParticipants() {
    const { data, pending, error, refresh } = useAsyncData('voting:participants', () =>
      adminFetch<RawParticipant[]>('/admin/partcipants'),
    )
    const participants = computed(() => (data.value ?? []).map(mapParticipant))
    return { participants, pending, error, refresh }
  }

  function createEvent(name: string, participantIds: number[]): Promise<RawEvent> {
    return adminFetch<RawEvent>('/admin/events', {
      method: 'POST',
      body: { title: name.trim(), partcipant_ids: participantIds },
    })
  }

  function closeEvent(id: number): Promise<RawEvent> {
    return adminFetch<RawEvent>(`/admin/events/${id}/close`, { method: 'PATCH' })
  }

  function addParticipant(name: string, avatar: string): Promise<Participant> {
    return adminFetch<RawParticipant>('/admin/partcipants', {
      method: 'POST',
      body: { nickname: name.trim(), avatar },
    }).then(mapParticipant)
  }

  function addVote(eventId: number, participantId: number, email: string): Promise<unknown> {
    return publicFetch('/votes', {
      method: 'POST',
      body: { event_id: eventId, partcipant_id: participantId, email },
    })
  }

  function totalVotes(event: VotingEvent): number {
    return Object.values(event.votes).reduce((sum, n) => sum + n, 0)
  }

  function votePercent(event: VotingEvent, participantId: number): number {
    const total = totalVotes(event)
    if (total === 0) return 0
    return Math.round(((event.votes[participantId] ?? 0) / total) * 100)
  }

  return {
    loadEvents,
    loadEvent,
    loadParticipants,
    createEvent,
    closeEvent,
    addParticipant,
    addVote,
    totalVotes,
    votePercent,
  }
}
