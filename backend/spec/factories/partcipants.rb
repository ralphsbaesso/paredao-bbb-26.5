FactoryBot.define do
  factory :partcipant do
    nickname { Faker::Name.unique.name }
    avatar { rand(10).to_s }
  end
end
