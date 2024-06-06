class Review < ApplicationRecord
  belongs_to :course
  belongs_to :user

  # Used to serialize the review model on the go without having to render
  def serialized_review
    ActiveModelSerializers::SerializableResource.new(self, serializer: ReviewSerializer).as_json
  end
end
