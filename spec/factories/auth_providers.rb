FactoryBot.define do
  factory :auth_provider do
    user { nil }
    auth_provider { "" }
    metadata { "" }
  end
end
