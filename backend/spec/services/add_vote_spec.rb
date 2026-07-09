# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddVote do
  describe '#call' do
    it 'must add one vote' do
      event = create(:event)
      email = Faker::Internet.email
      partcipant = create(:partcipant)

      expect do
        AddVote.call(event_id: event.id, email: email, partcipant_id: partcipant.id)
    end.to change { Vote.count }.by(1)

    last_vote = Vote.last
      expect(last_vote.partcipant_id).to eq(partcipant.id)
      expect(last_vote.email).to eq(email)
    end
  end
end
