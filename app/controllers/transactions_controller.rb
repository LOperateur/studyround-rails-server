class TransactionsController < ApplicationController
  require 'flutterwave_sdk'

  wrap_parameters format: []

  def initiate
    transaction_ref = loop do
      ref = SecureRandom.hex(10)
      break ref if !Transaction.exists?(transaction_ref: ref)
    end

    # t = current_user.transactions.build
    # t.transaction_status = :transaction_status_pending
    # t.transaction_ref = transaction_ref
    # t.save!

    render json: { data: { transaction_ref: transaction_ref } }, status: :ok
  end

  def verify
    flw = Flutterwave.new(ENV["FLUTTERWAVE_PUBLIC_KEY"], ENV["FLUTTERWAVE_SECRET_KEY"], ENV["FLUTTERWAVE_ENCRYPTION_KEY"])

    begin
      transactions = Transactions.new(flw)
      response = transactions.verify_transaction verify_transaction_params[:transaction_id]
    rescue
      raise Errors::BaseError.new(message: "Unable to process this transaction", status: 400)
    end

    if response['data']['status'] === "successful"
      # Success! Confirm the customer's payment
      build_flw_success_response response['data']
    else
      # Inform the customer their payment was unsuccessful
      build_flw_error_response response
    end
  end

  private

  def build_flw_success_response(data)
    transaction = Transaction.find_by(transaction_ref: data['tx_ref']) ||
      Transaction.new(transaction_ref: data['tx_ref'], transaction_status: :transaction_status_pending, buyer: current_user)

    if current_user != transaction.buyer
      raise Errors::BaseError.new(message: "Invalid user", status: 400)
    end

    if transaction.transaction_status_pending?
      transaction.transaction_status = :transaction_status_completed
    else
      raise Errors::BaseError.new(message: "Transaction already processed", status: 400)
    end

    transaction.external_txn_id = data['id']
    transaction.purchase_item_id = data['meta']['item_id']
    transaction.purchase_item_type = data['meta']['item_type']
    transaction.purchase_price = data['amount']
    transaction.purchase_currency = data['purchase_currency']
    transaction.completed_at = Time.now
    transaction.extra = data

    if data['card'].present?
      save_card data['card']
      transaction.payment_method = :payment_method_card
    else
      transaction.payment_method = :payment_method_others
    end

    # transaction.save!
    render json: transaction
  end

  def build_flw_error_response(response) end

  def save_card(card) end

  def verify_transaction_params
    params.permit(:transaction_id)
  end

end
