class Category < ApplicationRecord

  has_many :interests, dependent: :destroy
  has_many :users, through: :interests
  has_many :categorizations, dependent: :destroy
  has_many :courses, through: :categorizations

  # Used to serialize the category model for categorised courses on the go without having to render
  def serialized_categorised_course
    ActiveModelSerializers::SerializableResource.new(self, serializer: CategorisedCourseSerializer).as_json
  end
end
