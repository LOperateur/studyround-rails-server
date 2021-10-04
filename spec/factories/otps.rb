FactoryBot.define do
  factory :otp do
    user_identity { "MyString" }
    otp { "MyString" }
    auth_type { 1 }
    tries { 1 }
  end
end
