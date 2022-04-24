FactoryBot.define do
  factory :review do
    course { nil }
    user { nil }
    rating { 1 }
    review { "MyText" }
  end
end
