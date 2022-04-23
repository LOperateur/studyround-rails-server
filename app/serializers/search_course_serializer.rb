class SearchCourseSerializer < CourseSerializer
  type :course

  has_many :categories, serializer: MiniCategorySerializer

end


