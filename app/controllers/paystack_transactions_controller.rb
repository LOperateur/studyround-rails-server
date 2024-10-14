class PaystackTransactionsController < TransactionsController

  def initiate
    amount = initiate_transactions_params[:amount]
    item_id = initiate_transactions_params[:item_id]
    item_type = initiate_transactions_params[:item_type]

    if amount.blank? || item_id.blank? || item_type.blank?
      raise Errors::BaseError.new(message: "Invalid request, missing required data", status: 400)
    end

    conn = Faraday.new(
      url: "https://api.paystack.co",
      headers: {
        'Authorization' => "Bearer #{ENV["PAYSTACK_SECRET_KEY"]}",
        'Content-Type' => 'application/json',
      }
    )

    post_data = {
      email: current_user.email,
      amount: amount * 100,
      metadata: { item_id: item_id, item_type: item_type }
    }

    begin
      response = conn.post("/transaction/initialize") do |req|
        req.body = post_data.to_json
      end
    rescue
      raise Errors::BaseError.new(message: "Unable to initiate transaction, please try again later", status: 400)
    end

    access_code = JSON.parse(response.body)['data']['access_code']
    transaction_ref = JSON.parse(response.body)['data']['reference']
    render json: { data: { access_code: access_code, transaction_ref: transaction_ref } }, status: :ok
  end

  def verify
    transaction_ref = verify_transaction_params[:transaction_ref]

    conn = Faraday.new(
      url: "https://api.paystack.co",
      headers: { 'Authorization' => "Bearer #{ENV["PAYSTACK_SECRET_KEY"]}" }
    )

    begin
      response = conn.get("/transaction/verify/#{transaction_ref}")
      response_json = JSON.parse(response.body)
    rescue => error
      build_trx_response(error, transaction_ref, :transaction_status_pending)
      raise Errors::BaseError.new(message: "Unable to verify this transaction, please contact customer care", status: 400)
    end

    if response_json['data']&.[]('status') === "success"
      # Success! Confirm the customer's payment
      build_trx_success_response response_json['data']
    else
      # Inform the customer their payment was unsuccessful
      build_trx_response(response_json, transaction_ref, :transaction_status_cancelled)
      raise Errors::BaseError.new(message: "Payment not completed, please contact customer care", status: 400)
    end
  end

  def process_transaction
    conn = Faraday.new(
      url: "https://api.paystack.co",
      headers: {
        'Authorization' => "Bearer #{ENV["PAYSTACK_SECRET_KEY"]}",
        'Content-Type' => 'application/json',
      }
    )

    begin
      card = current_user.financial_cards.find(process_transaction_params[:card_id])
      token = card.token
    rescue
      raise Errors::NotFoundError.new(message: "Unable to find payment method attached")
    end

    unless card.is_paystack_card?
      raise Errors::BaseError.new(message: "Invalid card", status: 400)
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

    post_data = {
      authorization_code: token,
      amount: price * 100,
      email: current_user.email,
      metadata: {
        item_id: process_transaction_params[:item_id],
        item_type: process_transaction_params[:item_type]
      }
    }

    # Only used in case of errors
    tx_ref = generate_transaction_ref("paystack")

    begin
      response = conn.post("/transaction/charge_authorization") do |req|
        req.body = post_data.to_json
      end
    rescue => error
      build_trx_error_response(error, tx_ref, currency, price)
      raise Errors::BaseError.new(message: "Unable to charge payment method, please contact customer care", status: 400)
    end

    response_json = JSON.parse(response.body)
    logger.info response_json

    if response_json['data']&.[]('status') === "success"
      # Success! Confirm the customer's payment
      build_trx_success_response(response_json['data'], false)
    else
      build_trx_error_response(response_json, tx_ref, currency, price)
      raise Errors::BaseError.new(message: "Payment failed, please contact customer care", status: 400)
    end
  end

  private

  def build_trx_success_response(data, save_card = true)
    transaction = Transaction.find_by(transaction_ref: data['reference']) ||
      Transaction.new(transaction_ref: data['reference'], transaction_status: :transaction_status_pending, buyer: current_user)

    if current_user != transaction.buyer
      raise Errors::BaseError.new(message: "Invalid user", status: 400)
    end

    if transaction.transaction_status_pending?
      transaction.transaction_status = :transaction_status_completed
    else
      raise Errors::BaseError.new(message: "Transaction already processed", status: 400)
    end

    begin
      transaction.external_txn_id = data['id']
      if data['metadata'].present?
        transaction.purchase_item_id = data.dig('metadata', 'item_id')
        transaction.purchase_item_type = data.dig('metadata', 'item_type')
      else
        raise Errors::BaseError.new
      end
      transaction.purchase_price = (data['amount'].to_f) / 100
      transaction.purchase_currency = data['currency']
      transaction.completed_at = Time.now
      transaction.extra = data # Todo: Remove card token from this data

      if data['channel'].presence == "card"
        save_card(data['authorization']) if save_card
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
    rescue
      raise Errors::BaseError.new(message: "Unable to process transaction data, please contact customer care", status: 400)
    end

    transaction.save!
    render json: transaction, root: :data, status: :created
  end

  def save_card(card)
    if card['authorization_code'].nil? || card['authorization_code'].blank?
      # Don't save cards without the token
      return
    end

    new_card = current_user.financial_cards.build(
      country: card['country_code'],
      expiry: "#{card['exp_month']}/#{card['exp_year'].last(2)}",
      first_six: card['bin'],
      issuer: card['bank'],
      last_four: card['last4'],
      token: card['authorization_code'],
      card_type: card['card_type'],
      provider: "paystack",
    )

    # If the card token doesn't exist, (i.e. it's a new card token), attempt to save it
    if FinancialCard.where(token: new_card.token).empty?
      # Prevent saving the same card twice for a user assuming they open the modal again
      # First check if the card exists for this user with the same first_six, last_four and expiry
      existing_card = FinancialCard.where(
        first_six: new_card.first_six,
        last_four: new_card.last_four,
        expiry: new_card.expiry,
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

  def initiate_transactions_params
    params.permit(:amount, :item_id, :item_type)
  end
end
