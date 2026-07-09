# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events', type: :request do
  describe 'GET /events' do
    it 'lists events (open and closed), newest first, with participants and tallies' do
      p1, p2 = create_list(:partcipant, 2)
      open_event = create(:event, title: 'Aberto', partcipants: [p1, p2])
      closed_event = create(:event, title: 'Encerrado', closed_at: 1.hour.ago, partcipants: [p1, p2])

      create_list(:vote, 3, event: open_event, partcipant: p1)
      create(:vote, event: open_event, partcipant: p2)

      get events_path

      expect(response).to have_http_status(200)
      body = response.parsed_body
      expect(body.map { |e| e['id'] }).to eq([closed_event.id, open_event.id])

      listed_open = body.find { |e| e['id'] == open_event.id }
      expect(listed_open['title']).to eq('Aberto')
      expect(listed_open['closed_at']).to be_nil
      expect(listed_open['partcipants'].map { |p| p['id'] }).to contain_exactly(p1.id, p2.id)
      expect(listed_open['votes']).to eq(p1.id.to_s => 3, p2.id.to_s => 1)
      expect(listed_open['total_votes']).to eq(4)
    end

    it 'returns an empty array when there are no events' do
      get events_path

      expect(response).to have_http_status(200)
      expect(response.parsed_body).to eq([])
    end
  end

  describe 'GET /events/:id' do
    it 'returns a single event with its scoreboard' do
      p1, p2 = create_list(:partcipant, 2)
      event = create(:event, partcipants: [p1, p2])
      create_list(:vote, 2, event: event, partcipant: p1)

      get event_path(event)

      expect(response).to have_http_status(200)
      body = response.parsed_body
      expect(body['id']).to eq(event.id)
      expect(body['votes']).to eq(p1.id.to_s => 2, p2.id.to_s => 0)
      expect(body['total_votes']).to eq(2)
    end

    context 'when the event does not exist' do
      it do
        get event_path(0)

        expect(response).to have_http_status(404)
        expect(response.parsed_body['errors']).to eq(['Evento inválido'])
      end
    end
  end

  describe 'GET /events/:id/report' do
    it 'returns totals, per-participant counts and votes per hour' do
      p1, p2 = create_list(:partcipant, 2)
      event = create(:event, partcipants: [p1, p2])
      create_list(:vote, 2, event: event, partcipant: p1)
      create(:vote, event: event, partcipant: p2)

      get report_event_path(event)

      expect(response).to have_http_status(200)
      body = response.parsed_body
      expect(body['event_id']).to eq(event.id)
      expect(body['total_votes']).to eq(3)
      expect(body['per_partcipant']).to contain_exactly(
        { 'partcipant_id' => p1.id, 'nickname' => p1.nickname, 'count' => 2 },
        { 'partcipant_id' => p2.id, 'nickname' => p2.nickname, 'count' => 1 }
      )
      expect(body['per_hour'].sum { |bucket| bucket['count'] }).to eq(3)
    end

    context 'when the event does not exist' do
      it do
        get report_event_path(0)

        expect(response).to have_http_status(404)
        expect(response.parsed_body['errors']).to eq(['Evento inválido'])
      end
    end
  end
end
