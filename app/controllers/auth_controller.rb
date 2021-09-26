class AuthController < ApplicationController
  wrap_parameters format: []

  def generate_otp
    email = generate_otp_params[:user_identity]
    type = (!params[:resend] || params[:resend] == "false") ? :type_verify_email : :type_forgot_password

    if type == :type_verify_email # Sign up
      raise Errors::AuthenticationError.new(message: "An account is already associated with this email") if User.exists?(email: email)
    end

    # Check for existing OTP
    otp_object = Otp.find_by(user_identity: email)

    # If otp exists and it isn't up to 12 hours old yet
    if otp_object && otp_object.created_at + 12.hours > Time.now
      token = JsonWebToken.decode(otp_object.otp)

      if token # is not yet expired
        # Do nothing really
        render json: { data: { otp_id: otp_object.id }, status: "already_sent" }, status: :ok

      elsif otp_object.tries < 3
        # if it's expired, retry sending again
        otp_code = random_otp

        otp_object.otp = JsonWebToken.encode({ otp: otp_code }, 10.minutes.from_now)
        otp_object.tries = otp_object.tries + 1

        begin
          otp_object.save!
          UserMailer.with(email: email, otp: otp_code).verify_otp_email.deliver_later
          render json: { data: { otp_id: otp_object.id }, status: :success }, status: :created
        rescue
          raise Errors::AuthenticationError.new(message: "Unable to generate OTP")
        end

      else
        # If they've exceeded the tries (2 max), then inform them
        raise Errors::AuthenticationError.new(message: "Too many tries, please attempt OTP generation later", status: 429)
      end

    else # No Otp record for email, or record is older than 12 hours
      # First check if an otp record is actually present
      # then delete it
      if otp_object
        otp_object.delete!
      end

      # then generate and store the new otp, and send an email
      otp_code = random_otp
      new_otp_object = Otp.new(user_identity: email, otp: JsonWebToken.encode({ otp: otp_code }, 10.minutes.from_now), tries: 1)
      begin
        new_otp_object.save!
        UserMailer.with(email: email, otp: otp_code).verify_otp_email.deliver_later
        render json: { data: { otp_id: new_otp_object.id }, status: :success }, status: :created
      rescue
        raise Errors::AuthenticationError.new(message: "Unable to generate OTP")
      end
    end
  end

  def signup
    raise Errors::AuthenticationError.new(message: "Username already taken") if User.exists?(username: signup_params[:username])
    raise Errors::AuthenticationError.new(message: "Email already taken") if User.exists?(email: signup_params[:email])

    user = User.new(signup_params)
    user.save!
    access_token = create_access_token(user)
    refresh_token = create_refresh_token(user)

    render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }
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
