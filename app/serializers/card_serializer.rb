class CardSerializer < ActiveModel::Serializer
  attributes :id, :masked_pan, :country, :expiry, :card_type, :provider

  def masked_pan
    "#{object.first_six[0..3]}-#{object.first_six[4..-1]}XX-XXXX-#{object.last_four}"
  end

  def card_type
    if object.card_type&.upcase&.include? "MASTERCARD"
      "MASTERCARD"
    elsif object.card_type&.upcase&.include? "VISA"
      "VISA"
    else
      object.card_type&.upcase
    end
  end
end