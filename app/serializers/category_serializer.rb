class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :level, :image_url
end
