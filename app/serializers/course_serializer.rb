class CourseSerializer < ActiveModel::Serializer
  attributes :id, :title, :rating, :image_url, :currency, :price,
             :formatted_price, :sale_status, :version, :test

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

  def formatted_price
    if object.sale_status_free?
      return 'Free'
    else
      case object.currency
      when 'NGN'
        price = "₦#{object.price}"
      when 'USD'
        price = "$#{object.price}"
      when 'EUR'
        price = "€#{object.price}"
      when 'GBP'
        price = "£#{object.price}"
      else
        price = "#{object.currency} #{object.price}"
      end

      if object.sale_status_explanations?
        price += " - Explanations"
      end

      return price
    end
  end
end
