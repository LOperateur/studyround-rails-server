FactoryBot.define do
  factory :user do
    username { "MyString" }
    password_digest { "MyString" }
    first_name { "MyString" }
    last_name { "MyString" }
    other_name { "MyString" }
    email { "MyString" }
    date_of_birth { "2021-05-16" }
    creator { false }
    status { 1 }
    occupation { "MyString" }
    country { "MyString" }
    pro_account { false }
    profile_image_url { "MyString" }
    about { "MyText" }
    certified { false }
    preferences { "" }
  end
end
