class ReviewSerializer < ActiveModel::Serializer
  attributes :id, :rating, :review

  belongs_to :user, serializer: ProfileSerializer
end
