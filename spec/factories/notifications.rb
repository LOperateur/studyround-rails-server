FactoryBot.define do
  factory :notification do
    user { nil }
    content { "MyText" }
    category { 1 }
    read { false }
  end
end
