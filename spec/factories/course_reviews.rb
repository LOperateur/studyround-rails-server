FactoryBot.define do
  factory :course_review do
    course { nil }
    user { nil }
    rating { 1 }
    review { "MyText" }
  end
end
