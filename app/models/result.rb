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

  # Used to serialize the result model (with session data) on the go without having to render
  def serialized_result
    ActiveModelSerializers::SerializableResource.new(self, serializer: SessionResultSerializer).as_json
  end

  # Used to serialize the result model (with profile data) on the go without having to render
  def serialized_profile_result
    ActiveModelSerializers::SerializableResource.new(self, serializer: ProfileResultSerializer).as_json
  end

  def send_test_completion_email
    ResultMailer.with(
      email: self.user.email,
      title: self.course.title,
      score: "#{self.score}/#{self.total}",
      result_id: self.id,
    ).test_results_email.deliver_later
  end
end
