FactoryBot.define do
  factory :course_collaborator do
    course { nil }
    user { nil }
    role { 1 }
  end
end
