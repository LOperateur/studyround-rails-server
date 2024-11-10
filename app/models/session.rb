class Session < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :course, optional: true
  has_one :result, foreign_key: :session_key # Using custom session_key

  has_many :course_session_links, -> { order(order: :asc) }, dependent: :destroy
  has_many :multi_courses, through: :course_session_links, source: :course

  enum session_type: {
    quiz: 1,
    practice: 2,
    study: 3,
    test: 4,
  }, _prefix: true

  # Used to serialize the session model on the go without having to render
  def serialized_session
    SessionSerializer.new(self).as_json
  end
end
