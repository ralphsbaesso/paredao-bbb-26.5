# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Events', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:token) { admin_user.sessions.create!(expires_at: Session.ttl.from_now).token }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'POST /admin/events' do
    it 'creates an Event with 2 partcipants' do
      partcipants = create_list(:partcipant, 2)
      title = 'Primeiro paredão'

      expect do
        post admin_events_path,
          params: { title: title, partcipant_ids: partcipants.map(&:id) },
          headers: auth_headers

        expect(response).to have_http_status(201)
      end.to change { Event.count }.by(1)

      event = Event.last
      expect(event.title).to eq(title)
      expect(event.partcipants.count).to eq(2)
    end

    it 'creates an Event with 3 partcipants' do
      partcipants = create_list(:partcipant, 3)

      expect do
        post admin_events_path,
          params: { title: 'Paredão triplo', partcipant_ids: partcipants.map(&:id) },
          headers: auth_headers

        expect(response).to have_http_status(201)
      end.to change { Event.count }.by(1)

      expect(Event.last.partcipants.count).to eq(3)
    end

    it 'creates an Event with 4 partcipants' do
      partcipants = create_list(:partcipant, 4)

      expect do
        post admin_events_path,
          params: { title: 'Paredão quádruplo', partcipant_ids: partcipants.map(&:id) },
          headers: auth_headers

        expect(response).to have_http_status(201)
      end.to change { Event.count }.by(1)

      expect(Event.last.partcipants.count).to eq(4)
    end

    context 'with errors' do
      context 'fewer than 2 partcipants' do
        it do
          partcipants = create_list(:partcipant, 1)

          expect do
            post admin_events_path,
              params: { title: 'Paredão solo', partcipant_ids: partcipants.map(&:id) },
              headers: auth_headers

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Número de participantes inválido'])
          end.to change { Event.count }.by(0)
        end
      end

      context 'more than 4 partcipants' do
        it do
          partcipants = create_list(:partcipant, 5)

          expect do
            post admin_events_path,
              params: { title: 'Paredão lotado', partcipant_ids: partcipants.map(&:id) },
              headers: auth_headers

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Número de participantes inválido'])
          end.to change { Event.count }.by(0)
        end
      end

      context 'blank title' do
        it 'treats nil title as invalid' do
          partcipants = create_list(:partcipant, 2)

          expect do
            post admin_events_path,
              params: { title: nil, partcipant_ids: partcipants.map(&:id) },
              headers: auth_headers

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Título inválido'])
          end.to change { Event.count }.by(0)
        end
      end

      context 'duplicate title' do
        it do
          title = 'Paredão repetido'
          create(:event, title: title)
          partcipants = create_list(:partcipant, 2)

          expect do
            post admin_events_path,
              params: { title: title, partcipant_ids: partcipants.map(&:id) },
              headers: auth_headers

            expect(response).to have_http_status(409)
            expect(response.parsed_body['errors']).to eq(['Título já existe'])
          end.to change { Event.count }.by(0)
        end
      end

      context 'without authentication' do
        it do
          partcipants = create_list(:partcipant, 2)

          post admin_events_path,
            params: { title: 'Sem token', partcipant_ids: partcipants.map(&:id) }

          expect(response).to have_http_status(401)
          expect(response.parsed_body).to eq('error' => 'unauthorized')
        end
      end
    end
  end

  describe 'PATCH /admin/events/:id/close' do
    it 'closes an open event' do
      event = create(:event)
      expect(event.closed_at).to be_nil

      patch close_admin_event_path(event), headers: auth_headers

      expect(response).to have_http_status(200)
      expect(event.reload.closed_at).to be_present
    end

    context 'with errors' do
      context 'event not found' do
        it do
          patch close_admin_event_path(0), headers: auth_headers

          expect(response).to have_http_status(404)
          expect(response.parsed_body['errors']).to eq(['Evento inválido'])
        end
      end

      context 'event already closed' do
        it 'does not reopen or change closed_at' do
          event = create(:event, closed_at: 1.hour.ago)

          expect do
            patch close_admin_event_path(event), headers: auth_headers

            expect(response).to have_http_status(409)
            expect(response.parsed_body['errors']).to eq(['Evento já encerrado'])
          end.not_to(change { event.reload.closed_at })
        end
      end
    end
  end
end
