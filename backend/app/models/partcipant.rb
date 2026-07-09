class Partcipant < ApplicationRecord
  AVATARS = %w[
    sun moon star cloud rain storm snow wind rainbow comet
    planet meteor dawn dusk spark ember frost breeze tide wave
    coral pearl dune mesa canyon river forest meadow blossom harvest
  ].freeze

  validates :nickname, presence: true, uniqueness: true
  validates :avatar, presence: true, inclusion: { in: AVATARS }
end
