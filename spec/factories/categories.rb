FactoryBot.define do
  factory :category do
    parent { nil }
    name { "MyString" }
    level { 1 }
    image_url { "MyString" }
  end
end
