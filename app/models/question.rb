class Question < ApplicationRecord
  belongs_to :course

  enum status: {
    status_draft: 1,
    status_published: 2,
  }
end
