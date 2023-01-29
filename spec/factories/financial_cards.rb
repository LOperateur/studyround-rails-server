FactoryBot.define do
  factory :financial_card do
    country { "MyString" }
    expiry { "MyString" }
    first_six { "MyString" }
    issuer { "MyString" }
    last_four { "MyString" }
    card_type { "Visa" }
    token { "MyString" }
    provider { "MyString" }
    user { nil }
  end
end
