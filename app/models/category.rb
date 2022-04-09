class Category < ApplicationRecord

  has_many :interests, dependent: :destroy
  has_many :users, through: :interests
end
