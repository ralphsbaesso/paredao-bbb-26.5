# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Partcipants', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:token) { admin_user.sessions.create!(expires_at: Session.ttl.from_now).token }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /admin/partcipants' do
    it 'lists partcipants' do
      create_list(:partcipant, 3)

      get admin_partcipants_path, headers: auth_headers

      expect(response).to have_http_status(200)
      expect(response.parsed_body.size).to eq(3)
    end

    context 'without authentication' do
      it do
        get admin_partcipants_path

        expect(response).to have_http_status(401)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
      end
    end
  end

  describe 'GET /admin/partcipants/:id' do
    it 'returns the partcipant' do
      partcipant = create(:partcipant)

      get admin_partcipant_path(partcipant), headers: auth_headers

      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(partcipant.id)
      expect(response.parsed_body['nickname']).to eq(partcipant.nickname)
    end

    context 'when not found' do
      it do
        get admin_partcipant_path(0), headers: auth_headers

        expect(response).to have_http_status(404)
        expect(response.parsed_body['errors']).to eq(['Participante inválido'])
      end
    end

    context 'without authentication' do
      it do
        partcipant = create(:partcipant)

        get admin_partcipant_path(partcipant)

        expect(response).to have_http_status(401)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
      end
    end
  end

  describe 'POST /admin/partcipants' do
    it 'creates a partcipant' do
      expect do
        post admin_partcipants_path,
          params: { nickname: 'Fulano', avatar: 'sun' },
          headers: auth_headers

        expect(response).to have_http_status(201)
      end.to change { Partcipant.count }.by(1)

      partcipant = Partcipant.last
      expect(partcipant.nickname).to eq('Fulano')
      expect(partcipant.avatar).to eq('sun')
    end

    context 'with errors' do
      context 'duplicate nickname' do
        it do
          create(:partcipant, nickname: 'Fulano')

          expect do
            post admin_partcipants_path,
              params: { nickname: 'Fulano', avatar: 'moon' },
              headers: auth_headers

            expect(response).to have_http_status(409)
            expect(response.parsed_body['errors']).to eq(['Apelido já existe'])
          end.to change { Partcipant.count }.by(0)
        end
      end

      context 'unknown avatar' do
        it do
          expect do
            post admin_partcipants_path,
              params: { nickname: 'Beltrano', avatar: 'inexistente' },
              headers: auth_headers

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Participante inválido'])
          end.to change { Partcipant.count }.by(0)
        end
      end

      context 'blank nickname' do
        it do
          expect do
            post admin_partcipants_path,
              params: { nickname: nil, avatar: 'star' },
              headers: auth_headers

            expect(response).to have_http_status(422)
            expect(response.parsed_body['errors']).to eq(['Participante inválido'])
          end.to change { Partcipant.count }.by(0)
        end
      end

      context 'without authentication' do
        it do
          post admin_partcipants_path,
            params: { nickname: 'Sem token', avatar: 'sun' }

          expect(response).to have_http_status(401)
          expect(response.parsed_body).to eq('error' => 'unauthorized')
        end
      end
    end
  end
end
