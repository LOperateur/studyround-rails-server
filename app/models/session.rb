class Session < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :course, optional: true

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

  # Manually set courses with order
  def set_multi_courses_with_order(courses)
    # Iterate over course_ids with index
    courses.each_with_index do |course, index|
      # Create a new link with the course_id and order based on the index
      course_session_links.create!(course_id: course.id, order: index + 1)
    end
  end
end
