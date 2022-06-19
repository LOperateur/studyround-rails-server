FactoryBot.define do
  factory :session do
    user { nil }
    course { nil }
    extra_id { "MyString" }
    duration { "" }
    current_question_number { 1 }
    session_type { 1 }
    device_id { "MyString" }
    web_tab_id { "MyString" }
    session_items { "" }
  end
end
