class TransactionsController < ApplicationController

  wrap_parameters format: []

  def initiate
  end

  def verify
  end

  def process_transaction
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

  def verify_transaction_params
    params.permit(:transaction_id, :transaction_ref)
  end

  def process_transaction_params
    params.permit(:item_id, :item_type, :card_id)
  end

end
