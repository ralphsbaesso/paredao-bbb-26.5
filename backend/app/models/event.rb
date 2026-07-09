class Event < ApplicationRecord
  has_many :event_participants, dependent: :destroy
  has_many :partcipants, through: :event_participants

  validates :title, presence: true, uniqueness: true
end
