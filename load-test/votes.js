// Teste de carga do `POST /votes` (paredao-bbb) com k6.
//
// Alvo: POST /votes — body JSON plano { event_id, partcipant_id, email }.
// Descobre event_id + participantes via GET /events (ou usa EVENT_ID/PARTICIPANT_IDS).
// Envia o header `load-test: True` (contrato da task 012).
//
// Pre-requisito: o app precisa estar no ar em BASE_URL com db:seed aplicado
// (um evento aberto com >= 2 participantes).
//
// Como rodar (via Docker, sem instalar o k6 — a partir da raiz do repo):
//
//   docker run --rm -i --network host \
//     -e BASE_URL=http://localhost:3000 \
//     -e SCENARIO=smoke \
//     -v "$PWD/load-test:/scripts" \
//     grafana/k6 run /scripts/votes.js
//
// Depois do smoke passar, repita com -e SCENARIO=ramp_to_1k para o cenario-alvo (~1000 req/s).
//
// Envs suportadas:
//   BASE_URL         (default http://localhost:3000)
//   SCENARIO         smoke (default) | ramp_to_1k
//   EVENT_ID         forca um event_id (pula a descoberta)
//   PARTICIPANT_IDS  lista separada por virgula, ex.: "1,2" (forca os participantes)

import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:3000').replace(/\/$/, '');
const SCENARIO = __ENV.SCENARIO || 'smoke';

const SCENARIOS = {
  // Sanidade: poucos VUs por ~30s. Rode este primeiro.
  smoke: {
    executor: 'constant-vus',
    vus: 5,
    duration: '30s',
  },
  // Cenario-alvo do desafio: 2 minutos exatos — 1o minuto subindo a carga
  // progressivamente de 0 ate 1000 req/s, 2o minuto sustentando o pico de 1000 req/s.
  // O executor arrival-rate dispara no relogio (open model), entao a duracao total
  // e deterministica (soma das stages = 120s), independente da latencia da app.
  ramp_to_1k: {
    executor: 'ramping-arrival-rate',
    startRate: 0,
    timeUnit: '1s',
    preAllocatedVUs: 200,
    // Folga alta de propósito: quando a app satura e a latencia sobe, o k6 precisa de
    // mais VUs concorrentes p/ manter a taxa de chegada. Se bater no teto, ele reporta
    // dropped_iterations — e o teste revela o teto real em vez de ser limitado pelo gerador.
    maxVUs: 2000,
    stages: [
      { target: 1000, duration: '60s' }, // minuto 1: rampa progressiva 0 -> 1000 req/s
      { target: 1000, duration: '60s' }, // minuto 2: sustenta o pico de 1000 req/s
    ],
  },
};

if (!SCENARIOS[SCENARIO]) {
  throw new Error(`SCENARIO invalido: "${SCENARIO}". Use um de: ${Object.keys(SCENARIOS).join(', ')}`);
}

export const options = {
  scenarios: { [SCENARIO]: SCENARIOS[SCENARIO] },
  // Thresholds mapeiam o SLO do README: 99% sem 5xx em < 500ms.
  // Se falharem, o k6 sai com codigo != 0.
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<500'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
  },
};

// Descobre um evento aberto e seus participantes. Roda uma vez, antes da carga.
export function setup() {
  // Override manual: pula a descoberta se as duas envs vierem preenchidas.
  if (__ENV.EVENT_ID && __ENV.PARTICIPANT_IDS) {
    const ids = __ENV.PARTICIPANT_IDS.split(',').map((s) => parseInt(s.trim(), 10)).filter(Boolean);
    if (ids.length < 1) {
      throw new Error('PARTICIPANT_IDS vazio/invalido. Ex.: PARTICIPANT_IDS="1,2"');
    }
    return { eventId: parseInt(__ENV.EVENT_ID, 10), participantIds: ids };
  }

  const res = http.get(`${BASE_URL}/events`);
  if (res.status !== 200) {
    throw new Error(`GET ${BASE_URL}/events retornou ${res.status}. O app esta no ar em BASE_URL?`);
  }

  let events;
  try {
    events = res.json();
  } catch (e) {
    throw new Error(`Resposta de /events nao e JSON valido: ${res.body}`);
  }
  if (!Array.isArray(events) || events.length === 0) {
    throw new Error('Nenhum evento encontrado. Suba e semeie o app (db:seed) antes de rodar a carga.');
  }

  // Prefere um evento aberto (closed_at null); cai no primeiro (mais recente) se nao houver.
  const event = events.find((e) => e.closed_at == null) || events[0];

  // O index sempre serializa `partcipants` (array com id) — fonte confiavel, presente
  // mesmo com 0 votos. Como fallback, usa as chaves do map `votes` (keyed by id, string).
  let participantIds = Array.isArray(event.partcipants)
    ? event.partcipants.map((p) => p.id).filter(Boolean)
    : [];
  if (participantIds.length === 0 && event.votes && typeof event.votes === 'object') {
    participantIds = Object.keys(event.votes).map((k) => parseInt(k, 10)).filter(Boolean);
  }

  if (participantIds.length === 0) {
    throw new Error(
      `Evento ${event.id} nao expos participantes em /events. ` +
        'Passe PARTICIPANT_IDS="a,b" manualmente ou revise o seed.'
    );
  }

  return { eventId: event.id, participantIds };
}

export default function (data) {
  const partcipantId = data.participantIds[Math.floor(Math.random() * data.participantIds.length)];
  const payload = JSON.stringify({
    event_id: data.eventId,
    partcipant_id: partcipantId, // grafia do backend ("partcipant") — proposital.
    email: `voter_${__VU}_${__ITER}@loadtest.bbb`,
  });

  const res = http.post(`${BASE_URL}/votes`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'load-test': 'True', // contrato da task 012: ignora o rate limiting.
    },
  });

  check(res, {
    'status is 201': (r) => r.status === 201,
    'body status ok': (r) => {
      try {
        return r.json('status') === 'ok';
      } catch (e) {
        return false;
      }
    },
  });
}
