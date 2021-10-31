FactoryBot.define do
  factory :course do
    creator { nil }
    title { "MyString" }
    sale_status { 1 }
    sub_topics { "MyString" }
    price { "9.99" }
    currency { 1 }
    private { false }
    test { false }
    about { "MyText" }
    image_url { "MyString" }
    version { 1 }
    test_expiration { "2021-10-31 21:24:16" }
    draft { false }
    draft_content { "" }
    course_status { 1 }
    next_edition { 1 }
    previous_edition { 1 }
    rating { 1 }
    instructions { "" }
    completed { false }
  end
end
