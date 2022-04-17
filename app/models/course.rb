class Course < ApplicationRecord
  belongs_to :creator, class_name: 'User'

  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :results
  has_many :questions
  has_many :course_reviews

  enum sale_status: {
    sale_status_free: 1,
    sale_status_explanations: 2,
    sale_status_paid: 3,
  }

  enum course_status: {
    course_status_normal: 1,
    course_status_suspended: 2,
  }
end
