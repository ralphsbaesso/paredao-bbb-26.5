FactoryBot.define do
  factory :partcipant do
    nickname { Faker::Name.unique.name }
    avatar { Partcipant::AVATARS.sample }
  end
end
