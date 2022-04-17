class CategorisedCourseSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :courses do
    object.courses.published_active_courses.limit(12)
  end
end
