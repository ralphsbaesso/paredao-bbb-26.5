# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Adm::CreatePartcipant do
  describe '#call' do
    it 'creates one Partcipant' do
      expect do
        result = Adm::CreatePartcipant.call(nickname: 'Fulano', avatar: 'sun')
        expect(result.status).to eq('success')
        expect(result.result_code).to eq(201)
        expect(result.errors).to be_blank
      end.to change { Partcipant.count }.by(1)

      partcipant = Partcipant.last
      expect(partcipant.nickname).to eq('Fulano')
      expect(partcipant.avatar).to eq('sun')
    end
  end

  context 'with errors' do
    context 'duplicate nickname' do
      it do
        create(:partcipant, nickname: 'Fulano')

        expect do
          result = Adm::CreatePartcipant.call(nickname: 'Fulano', avatar: 'moon')
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Apelido já existe'])
          expect(result.result_code).to eq(409)
        end.to change { Partcipant.count }.by(0)
      end
    end

    context 'unknown avatar' do
      it do
        expect do
          result = Adm::CreatePartcipant.call(nickname: 'Beltrano', avatar: 'inexistente')
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Participante inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Partcipant.count }.by(0)
      end
    end

    context 'blank nickname' do
      it do
        expect do
          result = Adm::CreatePartcipant.call(nickname: nil, avatar: 'star')
          expect(result.status).to eq('error')
          expect(result.errors).to eq(['Participante inválido'])
          expect(result.result_code).to eq(422)
        end.to change { Partcipant.count }.by(0)
      end
    end
  end
end
