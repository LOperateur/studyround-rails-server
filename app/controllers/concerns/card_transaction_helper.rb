module CardTransactionHelper
  extend ActiveSupport::Concern

  def process_card_transaction(item_id, card_id, item_type)
    transactions_controller = TransactionsController.new

    transactions_controller.request = request
    transactions_controller.response = response

    purchase_params = { item_id: item_id, card_id: card_id, item_type: item_type }

    transactions_controller.params = purchase_params

    transactions_controller.process_transaction
  end
end
