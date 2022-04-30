class FullCourseSerializer < CourseSerializer
  type :course
  attributes :review_count, :instructions, :test_expiration, :private

  has_many :categories, serializer: MiniCategorySerializer

  def review_count
    object.reviews.count
  end
end
