class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course

  # Quick note
  # For Belongs to, the joins is singular
  # Result.joins(:course).where(courses: {draft: false})
  #
  # For Has many/one, the joins is plural
  # User.joins(:results).where(results: {session_type: :session_type_practice})

  scope :published_active_course_results, -> { joins(:course).where(courses: { publish_status: :publish_status_published, course_status: :course_status_active, private: false }) }

  enum session_type: {
    session_type_quiz: 1,
    session_type_practice: 2,
    session_type_study: 3,
    session_type_test: 4,
  }
end
