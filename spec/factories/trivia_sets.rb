FactoryBot.define do
  factory :trivia_set do
    title { "MyString" }
    subtitle { "MyText" }
    course_ids { [] }
    course_bundle_ids { [] }
    creator { nil }
    rules { "" }
    dq_results { [] }
    private { false }
    expiration { "2025-02-01 10:49:53" }
  end
end
