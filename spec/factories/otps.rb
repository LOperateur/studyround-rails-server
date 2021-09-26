FactoryBot.define do
  factory :otp do
    user_identity { "MyString" }
    otp { "MyString" }
    tries { 1 }
  end
end
