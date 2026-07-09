# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddVote do
  describe '#call' do
    it 'must add one vote' do
      event = create(:event)
      email = Faker::Internet.email
      partcipant = create(:partcipant)

      expect do
        result = AddVote.call(event_id: event.id, email: email, partcipant_id: partcipant.id)
        expect(result.status).to eq('success')
        expect(result.result_code).to eq(201)
        expect(result.errors).to be_blank
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
          result = AddVote.call(event_id: event.id, email: email, partcipant_id: partcipant.id)
          expect(result.result_code).to eq(201)
        end
      end.to change { Vote.count }.by(3)
    end
  end

  context 'with errors' do
    context 'invalid email' do
      it do
        event = create(:event)
        email = 'invalid email'
        partcipant = create(:partcipant)

        expect do
          result = AddVote.call(event_id: event.id, email: email, partcipant_id: partcipant.id)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Email inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Vote.count }.by(0)
      end
    end

    context 'blank email' do
      it 'treats nil email as invalid' do
        event = create(:event)
        partcipant = create(:partcipant)

        expect do
          result = AddVote.call(event_id: event.id, email: nil, partcipant_id: partcipant.id)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Email inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Vote.count }.by(0)
      end
    end

    context 'event_id not present' do
      it do
        partcipant = create(:partcipant)

        expect do
          result = AddVote.call(email: Faker::Internet.email, partcipant_id: partcipant.id)
          expect(result.status).to eq('error')
          expect(result.errors).to include('Evento inválido')
          expect(result.result_code).to eq(404)
        end.to change { Vote.count }.by(0)
      end
    end

    context 'event_id invalid' do
      it do
        partcipant = create(:partcipant)

        expect do
          result = AddVote.call(event_id: 0, email: Faker::Internet.email, partcipant_id: partcipant.id)
          expect(result.status).to eq('error')
          expect(result.errors).to include('Evento inválido')
          expect(result.result_code).to eq(404)
        end.to change { Vote.count }.by(0)
      end
    end

    context 'partcipant_id not present' do
      it do
        event = create(:event)

        expect do
          result = AddVote.call(event_id: event.id, email: Faker::Internet.email)
          expect(result.status).to eq('error')
          expect(result.errors).to include('Participante inválido')
          expect(result.result_code).to eq(404)
        end.to change { Vote.count }.by(0)
      end
    end

    context 'partcipant_id invalid' do
      it do
        event = create(:event)

        expect do
          result = AddVote.call(event_id: event.id, email: Faker::Internet.email, partcipant_id: 0)
          expect(result.status).to eq('error')
          expect(result.errors).to include('Participante inválido')
          expect(result.result_code).to eq(404)
        end.to change { Vote.count }.by(0)
      end
    end
  end
end
