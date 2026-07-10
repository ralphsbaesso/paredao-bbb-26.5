# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Votes', type: :request do
  describe 'POST /votes' do
    it 'must add one vote' do
      allow(REDIS).to receive(:get).and_return(nil)

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
      allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

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
          allow(REDIS).to receive(:get).and_return(nil)

          event = create(:event)

          expect do
            post votes_path, params: { event_id: event.id, email: Faker::Internet.email, partcipant_id: 0 }

            expect(response).to have_http_status(404)
            expect(response.parsed_body['errors']).to include('Participante inválido')
          end.to change { Vote.count }.by(0)
        end
      end
    end

    context 'rate limiting' do
      let(:event) { create(:event) }
      let(:partcipant) { create(:partcipant) }
      let(:params) { { event_id: event.id, email: Faker::Internet.email, partcipant_id: partcipant.id } }

      it 'blocks requests above the limit with 429 and does not create a Vote' do
        expect do
          post votes_path, params: params
        end.to change { Vote.count }.by(0)

        expect(response).to have_http_status(:too_many_requests)
        expect(response.parsed_body['errors']).to eq(['Muitas requisições. Tente novamente em instantes.'])
        expect(response.headers['Retry-After']).to eq('1')
      end

      it 'ignores the limit for requests carrying the load-test header' do
        expect do
          post votes_path, params: params, headers: { 'load-test' => 'True' }
        end.to change { Vote.count }.by(1)
        expect(response).to have_http_status(201)
      end

      it 'fails open when Redis is unavailable' do
        allow(REDIS).to receive(:get).and_raise(Redis::BaseError.new('connection refused'))

        expect do
          post votes_path, params: params
        end.to change { Vote.count }.by(1)
        expect(response).to have_http_status(201)
      end
    end
  end
end
