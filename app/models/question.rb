class Question < ApplicationRecord
  belongs_to :course

  enum status: {
    status_draft: 1,
    status_active: 2,
  }
end
