class CardSerializer < ActiveModel::Serializer
  attributes :id, :country, :expiry, :first_six, :last_four, :card_type
end
