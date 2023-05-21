class MiniProfileSerializer < ActiveModel::Serializer
  type :user
  attributes :id, :username
end
