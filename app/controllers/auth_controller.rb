class AuthController < ApplicationController
  wrap_parameters format: []

  def generate_otp
    UserMailer.with(email: generate_otp_params[:user_identity], otp: random_otp).verify_otp_email.deliver_now
    render json: {}, status: :ok
  end

  def signup
    raise Errors::AuthenticationError.new(message: "Username already taken") if User.exists?(username: signup_params[:username])
    raise Errors::AuthenticationError.new(message: "Email already taken") if User.exists?(email: signup_params[:email])

    user = User.new(signup_params)
    user.save!
    access_token = create_access_token(user)

    render json: { data: user.serialized_user.merge({ "access_token": access_token }) }
  end

  private

  def create_access_token(user)
    JsonWebToken.encode(user_id: user.id)
  end

  def create_refresh_token(user)
    JsonWebToken.encode({ user_id: user.id }, 1.year.from_now)
  end

  def random_otp
    (0..9).to_a.shuffle[0..3].join
  end

  def generate_otp_params
    params.permit(:user_identity) || ActionController::Parameters.new
  end

  def signup_params
    params.permit(:email, :username, :password, :password_confirmation, :creator) || ActionController::Parameters.new
  end
end
