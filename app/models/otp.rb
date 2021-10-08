class Otp < ApplicationRecord
  before_save { self.user_identity.downcase! }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :user_identity, presence: true, uniqueness: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }

  enum auth_type: {
    auth_type_verify_email: 1,
    auth_type_forgot_password: 2
  }
end
