FactoryBot.define do
  factory :vote do
    association :event
    association :partcipant
    email { Faker::Internet.email }
  end
end
