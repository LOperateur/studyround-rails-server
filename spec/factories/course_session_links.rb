FactoryBot.define do
  factory :course_session_link do
    course { nil }
    session { nil }
    order { 1 }
  end
end
