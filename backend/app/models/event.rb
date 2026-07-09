class Event < ApplicationRecord
  has_many :event_participants, dependent: :destroy
  has_many :partcipants, through: :event_participants
  has_many :votes, dependent: :destroy

  validates :title, presence: true, uniqueness: true
end
