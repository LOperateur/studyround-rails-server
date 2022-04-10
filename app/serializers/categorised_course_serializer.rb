class CategorisedCourseSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :courses do
    object.courses.limit(12)
  end
end
