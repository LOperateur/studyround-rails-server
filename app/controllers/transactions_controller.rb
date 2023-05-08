class TransactionsController < ApplicationController
  require 'flutterwave_sdk'

  wrap_parameters format: []

  def initiate
    transaction_ref = generate_transaction_ref
    render json: { data: { transaction_ref: transaction_ref } }, status: :ok
  end

  def verify
    flw = Flutterwave.new(ENV["FLUTTERWAVE_PUBLIC_KEY"], ENV["FLUTTERWAVE_SECRET_KEY"], ENV["FLUTTERWAVE_ENCRYPTION_KEY"])

    begin
      transactions = Transactions.new(flw)
      response = transactions.verify_transaction verify_transaction_params[:transaction_id]
    rescue => error
      build_trx_response(error, verify_transaction_params[:transaction_ref], :transaction_status_pending)
      raise Errors::BaseError.new(message: "Unable to verify this transaction", status: 400)
    end

    if response['data']&.[]('status') === "successful"
      # Success! Confirm the customer's payment
      build_trx_success_response response['data']
    else
      # Inform the customer their payment was unsuccessful
      # Ideally this shouldn't be called even if the payment fails since flutterwave
      # won't dismiss the modal until success/cancel, but this serves as a check just in case
      build_trx_response(response, verify_transaction_params[:transaction_ref], :transaction_status_cancelled)
      raise Errors::BaseError.new(message: "Payment not completed, please contact customer care", status: 400)
    end
  end

  def process_transaction
    flw = Flutterwave.new(ENV["FLUTTERWAVE_PUBLIC_KEY"], ENV["FLUTTERWAVE_SECRET_KEY"], ENV["FLUTTERWAVE_ENCRYPTION_KEY"])
    charge = TokenizedCharge.new(flw)

    begin
      token = current_user.financial_cards.find(process_transaction_params[:card_id]).token
    rescue
      raise Errors::NotFoundError.new(message: "Unable to find payment method attached")
    end

    # Currently assuming all item_type's are courses
    case process_transaction_params[:item_type].to_sym
    when :course, :explanations
      course = Course.find(process_transaction_params[:item_id])
      price = course.price
      currency = course.currency
    else
      raise Errors::NotFoundError.new(message: "Unknown transaction item type")
    end

    tx_ref = generate_transaction_ref

    details = {
      token: token,
      currency: currency,
      country: "NG",
      amount: price,
      email: current_user.email,
      tx_ref: tx_ref,
      meta: {
        item_id: process_transaction_params[:item_id],
        item_type: process_transaction_params[:item_type]
      }
    }

    begin
      # FLW requires the keys to be strings to go through
      response = charge.tokenized_charge details.deep_stringify_keys
    rescue => error
      build_trx_error_response(error, tx_ref, currency, price)
      raise Errors::BaseError.new(message: "Unable to charge payment method, please contact customer care", status: 400)
    end

    if response['data']&.[]('status') === "successful"
      # Success! Confirm the customer's payment
      build_trx_success_response(response['data'], false)
    else
      build_trx_error_response(response, tx_ref, currency, price)
      raise Errors::BaseError.new(message: "Payment failed, please contact customer care", status: 400)
    end
  end

  def index
    transactions = current_user.transactions.order(created_at: :desc)
    paginated_transactions = paginate(transactions, params)

    render json: paginated_transactions, root: :data, meta: paginated_meta(paginated_transactions), status: :ok
  end

  def show
    transaction = current_user.transactions.find(params[:id])
    render json: transaction, root: :data, status: :ok
  end

  private

  def generate_transaction_ref
    email = current_user.email
    timestamp = Time.now.strftime('%s%L')

    input = "#{email}:#{timestamp}"

    hash = Digest::MurmurHash64A.rawdigest(input) # Returns an integer
    rnd = Random.new(hash) # Use that integer to seed a new random string

    "ul_flw_#{rnd.hex(10).first(16)}#{timestamp.last(4)}"
  end

  def build_trx_success_response(data, save_card = true)
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
    transaction.purchase_item_id = data.dig('meta', 'item_id') || process_transaction_params[:item_id] # Meta not passed for token charge
    transaction.purchase_item_type = data.dig('meta', 'item_type') || process_transaction_params[:item_type]
    transaction.purchase_price = data['amount']
    transaction.purchase_currency = data['currency']
    transaction.completed_at = Time.now
    transaction.extra = data # Todo: Remove card token from this data

    if data['card'].present?
      save_card(data['card']) if save_card
      transaction.payment_method = :payment_method_card
    else
      transaction.payment_method = :payment_method_others
    end

    if transaction.purchase_item_type_course?
      transaction.description = "Purchased #{Course.find(transaction.purchase_item_id).title}"
    elsif transaction.purchase_item_type_explanations?
      transaction.description = "Purchased explanations for #{Course.find(transaction.purchase_item_id).title}"
    else
      transaction.description = "User purchase transaction"
    end

    transaction.save!
    render json: transaction, root: :data, status: :created
  end

  def build_trx_error_response(data, tx_ref, currency, price)
    transaction = Transaction.new(transaction_ref: tx_ref, transaction_status: :transaction_status_failed, buyer: current_user)

    transaction.payment_method = :payment_method_card
    transaction.purchase_item_id = process_transaction_params[:item_id]
    transaction.purchase_item_type = process_transaction_params[:item_type]
    transaction.purchase_currency = currency
    transaction.purchase_price = price
    transaction.description = "User purchase transaction"
    transaction.extra = data

    transaction.save
  end

  def build_trx_response(data, tx_ref, status)
    transaction = Transaction.new(transaction_ref: tx_ref, transaction_status: status, buyer: current_user)
    transaction.extra = data
    transaction.description = "User purchase transaction"
    transaction.save
  end

  def save_card(card)
    if card['token'].nil? || card['token'].blank?
      # Don't save cards without the token
      return
    end

    new_card = current_user.financial_cards.build(
      country: card['country'],
      expiry: card['expiry'],
      first_six: card['first_6digits'],
      issuer: card['issuer'],
      last_four: card['last_4digits'],
      token: card['token'],
      card_type: card['type'],
      provider: "flutterwave",
    )

    # Prevent saving the same card twice for a user assuming they load the modal again
    if !FinancialCard.exists?(token: new_card.token) &&
      FinancialCard.where(
        first_six: new_card.first_six,
        last_four: new_card.last_four,
        expiry: new_card.expiry,
        user_id: current_user.id
      ).empty?
      new_card.save
    end
  end

  def verify_transaction_params
    params.permit(:transaction_id, :transaction_ref)
  end

  def process_transaction_params
    params.permit(:item_id, :item_type, :card_id)
  end

end
