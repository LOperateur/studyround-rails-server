class TransactionSerializer < ActiveModel::Serializer
  include CurrencyHelper

  attributes :id, :transaction_ref, :external_txn_id, :buyer_id, :purchase_item_id,
             :purchase_item_type, :purchase_currency, :purchase_price, :formatted_price,
             :transaction_status, :payment_method, :description, :completed_at, :started_at

  def started_at
    object.created_at
  end

  def formatted_price
    format_with_currency(object.purchase_price, object.purchase_currency)
  end
end
