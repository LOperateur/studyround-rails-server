class Otp < ApplicationRecord
  enum auth_type: {
    auth_type_verify_email: 1,
    auth_type_forgot_password: 2
  }
end
