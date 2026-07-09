class Vote < ApplicationRecord
  belongs_to :partcipant
  belongs_to :event
end
