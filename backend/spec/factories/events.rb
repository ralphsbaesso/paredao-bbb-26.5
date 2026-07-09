FactoryBot.define do
  factory :event do
    title { Faker::Name.unique.name }
  end
end
