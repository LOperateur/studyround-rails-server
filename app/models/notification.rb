class Notification < ApplicationRecord
  belongs_to :user

  enum category: {
    category_test_expired: 1,
    # Todo: Add more notification categories
  }
end
