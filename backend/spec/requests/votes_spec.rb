# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Votes', type: :request do
  describe 'POST /votes' do
    it 'must add one vote' do
      event = create(:event)
      email = Faker::Internet.email
      partcipant = create(:partcipant)

      expect do
        post votes_path, params: { event_id: event.id, email: email, partcipant_id: partcipant.id }

        expect(response).to have_http_status(201)
        expect(response.parsed_body).to eq('status' => 'ok')
      end.to change { Vote.count }.by(1)

      last_vote = Vote.last
      expect(last_vote.event_id).to eq(event.id)
      expect(last_vote.partcipant_id).to eq(partcipant.id)
      expect(last_vote.email).to eq(email)
    end

    it 'allows the same email to vote multiple times' do
      event = create(:event)
      partcipant = create(:partcipant)
      email = Faker::Internet.email

      expect do
        3.times do
          post votes_path, params: { event_id: event.id, email: email, partcipant_id: partcipant.id }
          expect(response).to have_http_status(201)
        end
      end.to change { Vote.count }.by(3)
    end

    context 'with errors' do
      context 'invalid email' do
        it do
          event = create(:event)
          partcipant = create(:partcipant)

          expect do
            post votes_path, params: { event_id: event.id, email: 'invalid email', partcipant_id: partcipant.id }

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Email inválido'])
          end.to change { Vote.count }.by(0)
        end
      end

      context 'blank email' do
        it 'treats nil email as invalid' do
          event = create(:event)
          partcipant = create(:partcipant)

          expect do
            post votes_path, params: { event_id: event.id, email: nil, partcipant_id: partcipant.id }

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Email inválido'])
          end.to change { Vote.count }.by(0)
        end
      end

      context 'event_id not present' do
        it do
          partcipant = create(:partcipant)

          expect do
            post votes_path, params: { email: Faker::Internet.email, partcipant_id: partcipant.id }

            expect(response).to have_http_status(404)
            expect(response.parsed_body['errors']).to include('Evento inválido')
          end.to change { Vote.count }.by(0)
        end
      end

      context 'event_id invalid' do
        it do
          partcipant = create(:partcipant)

          expect do
            post votes_path, params: { event_id: 0, email: Faker::Internet.email, partcipant_id: partcipant.id }

            expect(response).to have_http_status(404)
            expect(response.parsed_body['errors']).to include('Evento inválido')
          end.to change { Vote.count }.by(0)
        end
      end

      context 'partcipant_id not present' do
        it do
          event = create(:event)

          expect do
            post votes_path, params: { event_id: event.id, email: Faker::Internet.email }

            expect(response).to have_http_status(404)
            expect(response.parsed_body['errors']).to include('Participante inválido')
          end.to change { Vote.count }.by(0)
        end
      end

      context 'partcipant_id invalid' do
        it do
          event = create(:event)

          expect do
            post votes_path, params: { event_id: event.id, email: Faker::Internet.email, partcipant_id: 0 }

            expect(response).to have_http_status(404)
            expect(response.parsed_body['errors']).to include('Participante inválido')
          end.to change { Vote.count }.by(0)
        end
      end
    end
  end
end
