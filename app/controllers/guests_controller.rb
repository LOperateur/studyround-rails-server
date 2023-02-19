class GuestsController < ApplicationController
  wrap_parameters format: []

  def create
    email = create_guest_params[:email]

    if User.exists?(email: email)
      raise Errors::BaseError.new(
        message: "This email is already associated with a U-Learn account",
        action: :login,
        status: 400
      )
    end

    guest = Guest.where(email: email).first_or_initialize

    begin
      guest.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(guest.errors.to_h)
    end

    render json: guest, status: :created
  end

  def invite
    guest_id = params[:id]
    guest = Guest.find(guest_id)

    email = invite_guest_params[:email]
    score = invite_guest_params[:score]

    # Still check if the provided email is a user
    if User.exists?(email: email)
      raise Errors::BaseError.new(
        message: "This email is already associated with a U-Learn account",
        action: :login,
        status: 400
      )
    end

    begin
      guest.update!(email: email)
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(guest.errors.to_h)
    end

    pass_token = JsonWebToken.encode({ guest_id: guest_id }, 1.year.from_now)
    UserMailer.with(email: email, score: score, pass_token: pass_token).demo_result_signup_email.deliver_later
  end

  private

  def create_guest_params
    params.permit(:email)
  end

  def invite_guest_params
    params.permit(:email, :score)
  end
end
