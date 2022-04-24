class Course < ApplicationRecord
  belongs_to :creator, class_name: 'User'

  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :results
  has_many :questions
  has_many :reviews

  scope :published_active_courses, -> { where(publish_status: :publish_status_published, course_status: :course_status_active, private: false) }

  enum sale_status: {
    sale_status_free: 1,
    sale_status_explanations: 2,
    sale_status_paid: 3,
  }

  enum course_status: {
    course_status_active: 1,
    course_status_suspended: 2,
  }

  # Don't change the order of 1 and 2, referenced in migrations
  enum publish_status: {
    publish_status_draft: 1,
    publish_status_published: 2,
  }
end
