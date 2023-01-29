class CardsController < ApplicationController
  wrap_parameters format: []

  def index
    cards = paginate(current_user.financial_cards.order(created_at: :asc))
    render json: cards, root: :data, meta: paginated_meta(cards), each_serializer: CardSerializer
  end
end
