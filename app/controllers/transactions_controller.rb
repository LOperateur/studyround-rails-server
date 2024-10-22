class TransactionsController < ApplicationController

  wrap_parameters format: []

  def initiate
  end

  def verify
  end

  def process_transaction
    begin
      card = current_user.financial_cards.find(process_transaction_params[:card_id])
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

    item_id = process_transaction_params[:item_id]
    card_id = process_transaction_params[:card_id]
    item_type = process_transaction_params[:item_type]

    purchase_params = { item_id: item_id, card_id: card_id, item_type: item_type }

    transactions_controller.params = purchase_params

    render json: transactions_controller.process_transaction
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

  def generate_transaction_ref(identifier)
    email = current_user.email
    timestamp = Time.now.strftime('%s%L')

    input = "#{email}:#{timestamp}"

    hash = Digest::MurmurHash64A.rawdigest(input) # Returns an integer
    rnd = Random.new(hash) # Use that integer to seed a new random string

    "sr_#{identifier}_#{rnd.hex(10).first(16)}#{timestamp.last(4)}"
  end

  def build_trx_success_response(data, save_card)
  end

  def build_trx_error_response(data, tx_ref, currency, price)
    transaction = Transaction.new(transaction_ref: tx_ref, transaction_status: :transaction_status_failed, buyer: current_user, gateway: gateway)

    transaction.payment_method = :payment_method_card
    transaction.purchase_item_id = process_transaction_params[:item_id]
    transaction.purchase_item_type = process_transaction_params[:item_type]
    transaction.purchase_currency = currency
    transaction.purchase_price = price
    transaction.extra = data

    if transaction.purchase_item_type_course?
      transaction.description = "Purchased #{Course.find(transaction.purchase_item_id).title}"
    elsif transaction.purchase_item_type_explanations?
      transaction.description = "Purchased explanations for #{Course.find(transaction.purchase_item_id).title}"
    else
      transaction.description = "User purchase transaction"
    end

    transaction.save
  end

  def build_trx_response(data, tx_ref, status)
    transaction = Transaction.new(transaction_ref: tx_ref, transaction_status: status, buyer: current_user, gateway: gateway)
    transaction.extra = data
    transaction.description = "User purchase transaction"
    transaction.save
  end

  def gateway
  end

  def save_card(card)
  end

  def create_or_update_card(new_card)
    # If the card token doesn't exist, (i.e. it's a new card token), attempt to save it
    if FinancialCard.where(token: new_card.token).empty?
      # Prevent saving the same card twice for a user assuming they open the modal again
      # First check if the card exists for this user and provider with the same first_six, last_four and expiry
      existing_card = FinancialCard.where(
        first_six: new_card.first_six,
        last_four: new_card.last_four,
        expiry: new_card.expiry,
        provider: new_card.provider,
        user_id: current_user.id,
      ).take

      # If it exists, update the token
      if existing_card.present?
        existing_card.token = new_card.token
        existing_card.save
      else
        # Otherwise, create a new card
        new_card.save
      end
    end
  end

  def verify_transaction_params
    params.permit(:transaction_id, :transaction_ref)
  end

  def process_transaction_params
    params.permit(:item_id, :item_type, :card_id)
  end

end
