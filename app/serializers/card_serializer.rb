class CardSerializer < ActiveModel::Serializer
  attributes :id, :masked_pan, :country, :expiry, :card_type

  def masked_pan
    "#{object.first_six[0..3]}-#{object.first_six[4..-1]}XX-XXXX-#{object.last_four}"
  end

end
