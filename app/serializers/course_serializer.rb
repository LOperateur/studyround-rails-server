class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url,
             :currency, :price, :sale_status, :version, :test

  belongs_to :creator, serializer: ProfileSerializer

  def image_url
    object.generated_image_url
  end
end
