class AuthController < ApplicationController
  skip_before_action :authorize!

  wrap_parameters format: []

  def generate_otp
    email = generate_otp_params[:user_identity].downcase
    auth_type = generate_otp_params[:type].blank? ? :auth_type_verify_email : generate_otp_params[:type].to_sym

    if auth_type != :auth_type_verify_email && auth_type != :auth_type_forgot_password
      raise Errors::BaseError.new(message: "Unknown authentication type", status: 400)
    end

    if auth_type == :auth_type_verify_email # Sign up
      raise Errors::AuthenticationError.new(message: "An account is already associated with this email") if User.exists?(email: email)
    end

    if auth_type == :auth_type_forgot_password # Forgot password
      raise Errors::AuthenticationError.new(message: "No existing user with this email") unless User.exists?(email: email)
    end

    # Check for existing OTP
    otp_object = Otp.find_by(user_identity: email)

    # If otp exists and it isn't up to 12 hours old yet
    if otp_object && otp_object.created_at + 12.hours > Time.now
      token = JsonWebToken.decode(otp_object.otp)

      # If token is not yet expired and it's not a resend request
      if token && generate_otp_params[:resend] != true
        # Do nothing really
        render json: otp_object, meta: { message: "Already sent" }, root: :data, status: :ok

      elsif otp_object.tries < 2
        # if it's expired or an explicit resend request, retry sending again
        # as long as the tries haven't been exceeded
        otp_code = random_otp

        otp_object.otp = JsonWebToken.encode({ otp: otp_code }, 10.minutes.from_now)
        otp_object.tries = otp_object.tries + 1

        begin
          otp_object.save!
        rescue ActiveRecord::RecordInvalid
          raise Errors::InvalidError.new(otp_object.errors.to_h)
        end
        UserMailer.with(email: email, otp: otp_code).verify_otp_email.deliver_later
        render json: otp_object, meta: { message: "Sent OTP successfully" }, root: :data, status: :created

      else
        # If they've exceeded the tries (2 max), then inform them
        raise Errors::AuthenticationError.new(message: "Too many tries, please attempt OTP generation later", status: 429)
      end

    else
      # No Otp record for email, or record is older than 12 hours
      # First check if an otp record is actually present
      # then delete it
      if otp_object
        otp_object.delete
      end

      # then generate and store the new otp, and send an email
      otp_code = random_otp
      new_otp_object = Otp.new(user_identity: email, otp: JsonWebToken.encode({ otp: otp_code }, 10.minutes.from_now), auth_type: auth_type, tries: 1)

      begin
        new_otp_object.save!
      rescue ActiveRecord::RecordInvalid
        raise Errors::InvalidError.new(new_otp_object.errors.to_h)
      end
      UserMailer.with(email: email, otp: otp_code).verify_otp_email.deliver_later
      render json: new_otp_object, meta: { message: "Sent OTP successfully" }, root: :data, status: :created
    end
  end

  def validate_otp
    raise Errors::NotFoundError.new(message: "No OTP record found for this user, try generating again") unless Otp.exists?(validate_otp_params[:otp_id])
    otp_object = Otp.find(validate_otp_params[:otp_id])

    email = otp_object.user_identity
    entered_otp = validate_otp_params[:otp]

    if otp_object.auth_type_verify_email?
      raise Errors::AuthenticationError.new(message: "An account is already associated with this email") if User.exists?(email: email)
    end

    token = JsonWebToken.decode(otp_object.otp)
    if token
      actual_otp = token[:otp]
    else
      raise Errors::AuthenticationError.new(message: "OTP has expired, try generating another")
    end

    if actual_otp == entered_otp
      render json: { data: { pass_token: JsonWebToken.encode({ otp_id: otp_object.id }, 1.hour.from_now) }, message: "success" }, status: :created
    else
      raise Errors::AuthenticationError.new(message: "OTP does not match, please try again")
    end
  end

  def signup
    is_otp_auth = false

    # Decode the pass token and obtain the email from it
    begin
      pass_token = signup_params[:pass_token]
      decoded_token = JsonWebToken.decode(pass_token)

      otp_object = Otp.find_by(id: decoded_token[:otp_id])
      if otp_object
        email = otp_object.user_identity
        is_otp_auth = true
      else
        guest = Guest.find_by(id: decoded_token[:guest_id])
        email = guest.email
      end

      if email.nil?
        raise Errors::AuthenticationError.new(message: "Authentication has expired, please try signing up again", action: :signup)
      end

    rescue
      raise Errors::AuthenticationError.new(message: "Authentication has expired, please try signing up again", action: :signup)
    end

    if is_otp_auth && !otp_object.auth_type_verify_email?
      raise Errors::AuthenticationError.new(message: "Wrong authentication type")
    end

    raise Errors::AuthenticationError.new(message: "Username already taken") if User.exists?(username: signup_params[:username].downcase)
    raise Errors::AuthenticationError.new(message: "Email: #{email} already taken") if User.exists?(email: email)

    user = User.new(signup_params.except(:pass_token))
    user.email = email

    begin
      user.save!
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(user.errors.to_h)
    end

    access_token = create_access_token(user)
    refresh_token = create_refresh_token(user)

    # Delete the OTP record
    if is_otp_auth
      otp_object.destroy
    end

    render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }
  end

  def login
    email_or_username = login_params[:user_identity].downcase
    is_email = email_or_username.include? "@"

    if is_email
      raise Errors::AuthenticationError.new(message: "Email does not exist") unless User.exists?(email: email_or_username)
    else
      raise Errors::AuthenticationError.new(message: "User does not exist") unless User.exists?(username: email_or_username)
    end

    user = is_email ? User.find_by(email: email_or_username) : User.find_by(username: email_or_username)

    if user && user.authenticate(login_params[:password])
      access_token = create_access_token(user)
      refresh_token = create_refresh_token(user)

      render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }
    else
      raise Errors::AuthenticationError.new(message: "Incorrect login details")
    end
  end

  def reset
    # Decode the pass token and obtain the email from it
    begin
      pass_token = reset_password_params[:pass_token]
      decoded_token = JsonWebToken.decode(pass_token)
      otp_object = Otp.find(decoded_token[:otp_id])
      email = otp_object.user_identity
    rescue
      raise Errors::AuthenticationError.new(message: "Authentication has expired, please try resetting password again")
    end

    unless otp_object.auth_type_forgot_password?
      raise Errors::AuthenticationError.new(message: "Wrong authentication type")
    end

    user = User.find_by(email: email)
    raise Errors::AuthenticationError.new(message: "No existing user with email: #{email}") unless user

    unless user.update_attributes(password: reset_password_params[:password],
                                  password_confirmation: reset_password_params[:password_confirmation])
      raise Errors::InvalidError.new(user.errors.to_h)
    end

    access_token = create_access_token(user)
    refresh_token = create_refresh_token(user, true)

    # Delete the OTP record
    otp_object.delete

    render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }

  end

  def refresh_token
    refresh_token = refresh_token_params[:refresh_token]
    decoded_refresh_token = JsonWebToken.decode(refresh_token)

    # First check the refresh token
    if decoded_refresh_token && decoded_refresh_token[:user_id]
      user_id = decoded_refresh_token[:user_id]
    else
      raise Errors::ForbiddenError.new(message: "Unauthorized, refresh token invalid or expired!")
    end

    # Then get the user encoded within the token
    user = User.find(user_id)
    if user
      # Only authorize if the sent token matches the one saved alongside the user in the DB
      saved_token_object = RefreshToken.find_by(user: user)
      saved_refresh_token = saved_token_object ? saved_token_object.token : nil
      raise Errors::ForbiddenError.new(message: "Unauthorized, refresh token invalid!") unless saved_refresh_token == refresh_token

      new_access_token = create_access_token(user)

      render json: { data: { "access_token": new_access_token} }

    else
      raise Errors::ForbiddenError.new(message: "User does not exist")
    end
  end

  private

  def create_access_token(user)
    JsonWebToken.encode(user_id: user.id)
  end

  def create_refresh_token(user, should_reset = false)
    # Find existing refresh token if it exists and should not reset
    if !should_reset && RefreshToken.exists?(user: user)
      refresh_token = RefreshToken.find_by(user: user).token
    else
      # A reset or non-existent token
      refresh_token = ""
    end

    # Generate and save/update a new refresh token if there wasn't a previous one or it's expired or is resetting
    unless JsonWebToken.decode(refresh_token)
      refresh_token = JsonWebToken.encode({ user_id: user.id }, 1.year.from_now)

      begin
        rt = RefreshToken.where(user: user).first_or_initialize
        rt.token = refresh_token
        rt.save!
      rescue ActiveRecord::RecordInvalid
        raise Errors::InvalidError.new(refresh_token.errors.to_h)
      end
    end

    refresh_token
  end

  def random_otp
    (0..9).to_a.shuffle[0..3].join
  end

  def generate_otp_params
    params.permit(:user_identity, :type, :resend) || ActionController::Parameters.new
  end

  def validate_otp_params
    params.permit(:otp_id, :otp) || ActionController::Parameters.new
  end

  def signup_params
    params.permit(:username, :password, :password_confirmation, :creator, :pass_token) || ActionController::Parameters.new
  end

  def login_params
    params.permit(:user_identity, :password) || ActionController::Parameters.new
  end

  def reset_password_params
    params.permit(:password, :password_confirmation, :pass_token) || ActionController::Parameters.new
  end

  def refresh_token_params
    params.permit(:refresh_token) || ActionController::Parameters.new
  end
end
