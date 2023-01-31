class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :transaction_ref, :external_txn_id, :buyer_id, :purchase_item_id, :purchase_item_type,
             :purchase_currency, :purchase_price, :transaction_status, :payment_method, :description, :completed_at
end
