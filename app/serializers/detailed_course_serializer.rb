class DetailedCourseSerializer < CourseSerializer
  type :course
  attributes :about, :review_count, :num_questions, :num_explanations

  has_many :categories, serializer: MiniCategorySerializer

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