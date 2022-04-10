FactoryBot.define do
  factory :result do
    user { nil }
    course { nil }
    score { 1 }
    total { 1 }
    duration { "" }
    mode { 1 }
    extra_id { "MyString" }
    session_items { "" }
  end
end
