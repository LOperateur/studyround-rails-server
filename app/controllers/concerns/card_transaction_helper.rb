module CardTransactionHelper
  extend ActiveSupport::Concern

  def process_card_transaction(item_id, card_id, item_type)
    begin
      card = current_user.financial_cards.find(card_id)
    rescue
      raise Errors::NotFoundError.new(message: "Unable to find payment method attached")
    end

    if card.is_flutterwave_card?
      transactions_controller = FlutterwaveTransactionsController.new
    elsif card.is_paystack_card?
      transactions_controller = PaystackTransactionsController.new
    else
      raise Errors::BaseError.new(message: "Unsupported payment method", status: 400)
    end

    transactions_controller.request = request
    transactions_controller.response = response

    purchase_params = { item_id: item_id, card_id: card_id, item_type: item_type }

    transactions_controller.params = purchase_params

    transactions_controller.process_transaction
  end
end
