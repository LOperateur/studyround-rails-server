class DetailedCourseSerializer < CourseSerializer
  type :course
  attributes :about, :review_count

  has_many :categories, serializer: MiniCategorySerializer

  def review_count
    object.reviews.count
  end
end