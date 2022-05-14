class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course

  # Quick note
  # For Belongs to, the joins is singular
  # Result.joins(:course).where(courses: {draft: false})
  #
  # For Has many/one, the joins is plural
  # User.joins(:results).where(results: {session_type: :practice})

  scope :published_active_course_results, -> { joins(:course).where(courses: { publish_status: :publish_status_published, course_status: :course_status_active, private: false }) }

  enum session_type: {
    quiz: 1,
    practice: 2,
    study: 3,
    test: 4,
  }, _prefix: true
end
