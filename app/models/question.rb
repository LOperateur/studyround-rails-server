class Question < ApplicationRecord
  belongs_to :course

  enum publish_status: {
    publish_status_draft: 1,
    publish_status_published: 2,
  }
end
