class CourseSerializer < ActiveModel::Serializer
  include CurrencyHelper

  attributes :id, :title, :rating, :image_url, :currency, :price,
             :formatted_price, :sale_status, :version, :test, :included_question_years

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
      price = format_with_currency(object.price, object.currency)
      if object.sale_status_explanations?
        price += " - Explanations"
      end

      return price
    end
  end

  def included_question_years
    object.questions.published_active_questions.distinct.pluck(:year).compact.sort
  end
end
