# Course serializer showing some detailed information
# on the course which can be presented to the general user base.
class UserCourseSerializer < CourseSerializer
  type :course
  attributes :course_status, :about, :included_question_years, :review_count, :num_questions, :num_explanations, :test_expiration

  has_many :categories, serializer: MiniCategorySerializer
  has_many :collaborators, serializer: ProfileSerializer

  def review_count
    object.reviews.count
  end

  def num_questions
    object.questions.published_active_questions.count
  end

  def num_explanations
    object.questions.published_active_questions.where.not(explanation: nil).count
  end
end
