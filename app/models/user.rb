class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  has_secure_password
  validates :password, presence: true
  validates :password_confirmation, presence: true
end
