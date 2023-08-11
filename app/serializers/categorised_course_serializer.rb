class CategorisedCourseSerializer < ActiveModel::Serializer
  type :category
  attributes :id, :name

  has_many :courses do
    object.courses.published_active_courses.ordered_by_result_count.limit(12)
  end
end
