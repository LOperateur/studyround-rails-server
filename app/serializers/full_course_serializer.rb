class FullCourseSerializer < CourseSerializer
  type :course
  attributes :about, :review_count, :instructions, :test_expiration,
             :private, :publish_status, :course_status, :completed

  has_many :categories, serializer: MiniCategorySerializer

  def review_count
    object.reviews.count
  end
end
