# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Adm::CreateEvent do
  describe '#call' do
    it 'must create one Event with 2 partcipants' do
      partcipants = create_list(:partcipant, 2)
      title = 'Primeiro paredão'

      expect do
        result = Adm::CreateEvent.call(title: title, partcipants: partcipants)
        expect(result.status).to eq('success')
        expect(result.result_code).to eq(201)
        expect(result.errors).to be_blank
      end.to change { Event.count }.by(1)

      event = Event.last
      expect(event.title).to eq(title)
      expect(event.partcipants.count).to eq(2)
    end

    it 'creates an Event with 3 partcipants' do
      partcipants = create_list(:partcipant, 3)

      expect do
        result = Adm::CreateEvent.call(title: 'Paredão triplo', partcipants: partcipants)
        expect(result.result_code).to eq(201)
        expect(result.data.partcipants.count).to eq(3)
      end.to change { Event.count }.by(1)
    end

    it 'creates an Event with 4 partcipants' do
      partcipants = create_list(:partcipant, 4)

      expect do
        result = Adm::CreateEvent.call(title: 'Paredão quádruplo', partcipants: partcipants)
        expect(result.result_code).to eq(201)
        expect(result.data.partcipants.count).to eq(4)
      end.to change { Event.count }.by(1)
    end
  end

  context 'with errors' do
    context 'fewer than 2 partcipants' do
      it do
        partcipants = create_list(:partcipant, 1)

        expect do
          result = Adm::CreateEvent.call(title: 'Paredão solo', partcipants: partcipants)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Número de participantes inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Event.count }.by(0)
      end
    end

    context 'more than 4 partcipants' do
      it do
        partcipants = create_list(:partcipant, 5)

        expect do
          result = Adm::CreateEvent.call(title: 'Paredão lotado', partcipants: partcipants)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Número de participantes inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Event.count }.by(0)
      end
    end

    context 'blank title' do
      it 'treats nil title as invalid' do
        partcipants = create_list(:partcipant, 2)

        expect do
          result = Adm::CreateEvent.call(title: nil, partcipants: partcipants)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Título inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Event.count }.by(0)
      end
    end

    context 'duplicate title' do
      it do
        title = 'Paredão repetido'
        create(:event, title: title)
        partcipants = create_list(:partcipant, 2)

        expect do
          result = Adm::CreateEvent.call(title: title, partcipants: partcipants)
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Título já existe'])
          expect(result.result_code).to eq(409)
        end.to change { Event.count }.by(0)
      end
    end
  end
end
