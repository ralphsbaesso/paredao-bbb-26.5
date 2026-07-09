# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Adm::CloseEvent do
  describe '#call' do
    it 'closes an open event' do
      event = create(:event)
      expect(event.closed_at).to be_nil

      result = Adm::CloseEvent.call(event_id: event.id)

      expect(result.status).to eq('success')
      expect(result.result_code).to eq(200)
      expect(result.errors).to be_blank
      expect(result.data.closed_at).to be_present
      expect(event.reload.closed_at).to be_present
    end
  end

  context 'with errors' do
    context 'event not found' do
      it do
        result = Adm::CloseEvent.call(event_id: 0)

        expect(result.status).to eq('error')
        expect(result.errors).to eq(['Evento inválido'])
        expect(result.result_code).to eq(404)
      end
    end

    context 'event_id not present' do
      it do
        result = Adm::CloseEvent.call

        expect(result.status).to eq('error')
        expect(result.errors).to eq(['Evento inválido'])
        expect(result.result_code).to eq(404)
      end
    end

    context 'event already closed' do
      it 'does not reopen or change closed_at' do
        closed_at = 1.hour.ago
        event = create(:event, closed_at: closed_at)

        expect do
          result = Adm::CloseEvent.call(event_id: event.id)

          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Evento já encerrado'])
          expect(result.result_code).to eq(409)
        end.not_to(change { event.reload.closed_at })
      end
    end
  end
end
