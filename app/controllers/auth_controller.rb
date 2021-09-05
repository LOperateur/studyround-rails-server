class AuthController < ApplicationController
  wrap_parameters format: []

  def signup
    raise Errors::AuthenticationError.new(message: "Username already taken") if User.exists?(username: signup_params[:username])
    raise Errors::AuthenticationError.new(message: "Email already taken") if User.exists?(email: signup_params[:email])

    user = User.new(signup_params)
    user.save!
    access_token = create_access_token(user)

    render json: { data: user.serialized_user.merge({ "token": access_token }) }
  end

  private

  def create_access_token(user)
    JsonWebToken.encode(user_id: user.id)
  end

  def create_refresh_token(user)
    JsonWebToken.encode({ user_id: user.id }, 1.year.from_now)
  end

  def signup_params
    params.permit(:email, :username, :password, :password_confirmation, :creator) || ActionController::Parameters.new
  end
end
