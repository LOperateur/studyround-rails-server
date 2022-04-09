class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :image_url

  def image_url
    if object.image_url.nil?
      nil
    else
      ActionController::Base.helpers.asset_path(object.image_url)
    end
  end
end
