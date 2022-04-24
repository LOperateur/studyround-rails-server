class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course

  # Quick note
  # For Belongs to, the joins is singular
  # Result.joins(:course).where(courses: {draft: false})
  #
  # For Has many/one, the joins is plural
  # User.joins(:results).where(results: {mode: :mode_practice})

  scope :published_active_course_results, -> { joins(:course).where(courses: { publish_status: :publish_status_published, course_status: :course_status_active, private: false }) }

  enum mode: {
    mode_quiz: 1,
    mode_practice: 2,
    mode_test: 3,
  }
end
