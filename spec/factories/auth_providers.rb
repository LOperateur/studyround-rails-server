FactoryBot.define do
  factory :auth_provider do
    user { nil }
    provider { "" }
    metadata { "" }
  end
end
