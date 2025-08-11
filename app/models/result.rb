class Result < ApplicationRecord
  belongs_to :user
  belongs_to :course, optional: true # Deprecated
  belongs_to :trivia_set, optional: true

  has_many :course_result_links, -> { order(order: :asc) }, dependent: :destroy
  has_many :multi_courses, through: :course_result_links, source: :course


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
    trivia: 5,
  }, _prefix: true

  # Used to serialize the result model (with session data) on the go without having to render
  def serialized_result
    SessionResultSerializer.new(self).as_json
  end

  # Used to serialize the result model (with profile data) on the go without having to render
  def serialized_profile_result
    ProfileResultSerializer.new(self).as_json
  end

  # TODO: Applies to Test and Trivia results, work on it later
  def disqualified
    false
  end

  def send_test_completion_email
    ResultMailer.with(
      email: self.user.email,
      title: self.course.title,
      score: "#{self.score}/#{self.total}",
      course_id: self.course.id,
      result_id: self.id,
    ).test_results_email.deliver_later
  end

  def send_trivia_completion_email
    ResultMailer.with(
      email: self.user.email,
      title: self.trivia_set.title,
      score: "#{self.score}/#{self.total}",
      trivia_id: self.trivia_set.id,
      result_id: self.id,
    ).trivia_results_email.deliver_later
  end

  # Manually set courses with order
  def set_multi_courses_with_order(courses)
    # Iterate over course_ids with index
    courses.each_with_index do |course, index|
      # Create a new link with the course_id and order based on the index
      course_result_links.create!(course_id: course.id, order: index + 1)
    end
  end

  def set_multi_course_ids_with_order(course_ids)
    # Iterate over course_ids with index
    course_ids.each_with_index do |course_id, index|
      # Create a new link with the course_id and order based on the index
      course_result_links.create!(course_id: course_id, order: index + 1)
    end
  end
end
