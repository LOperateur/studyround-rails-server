class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url,
             :currency, :price, :sale_status, :version, :test

  belongs_to :creator, serializer: ProfileSerializer

  # Todo: Consider making sale_status an array of sellable items at the DB level too
  def sale_status
    if object.sale_status_free?
      []
    else
      [object.sale_status]
    end
  end

  def image_url
    object.generated_image_url
  end
end
