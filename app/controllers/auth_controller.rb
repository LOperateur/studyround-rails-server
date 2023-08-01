class AuthController < ApplicationController
  skip_before_action :authorize!

  wrap_parameters format: []

  def random
    render json: [
      {
        "category": "PIGEON",
        "path": "pigeon/vladislav-nikonov-yVYaUSwkTOs-unsplash.jpg",
        "author": "Vladislav"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/arun-waghela-OLNQk7SsEIY-unsplash.jpg",
        "author": "Arun"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/shaquon-gibson-9Q3UL6wGjts-unsplash.jpg",
        "author": "Shaquon"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/abdullah-ahmad-NjHLcr2Rf5I-unsplash.jpg",
        "author": "Abdullah"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/nandkumar-patel-RPUD-n9V6E0-unsplash.jpg",
        "author": "Nandkumar"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/sara-kurfess-WJxYU_jpOHo-unsplash.jpg",
        "author": "Sara"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/mauro-tandoi-_jn3oS40sRM-unsplash.jpg",
        "author": "Mauro"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/victor-ajayi-FpqWLiwInj0-unsplash.jpg",
        "author": "Victor"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/alan-qIrxgh8WupA-unsplash.jpg",
        "author": "Alan"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/navi-WKS_VSI68jw-unsplash.jpg",
        "author": "Navi"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/chandan-chaurasia-B1IKvDctXAo-unsplash.jpg",
        "author": "Chandan"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/nisarg-bhavsar-iebgqJeijzY-unsplash.jpg",
        "author": "Nisarg"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/rafael-rodrigues-machado-w4Ee-yF16F0-unsplash.jpg",
        "author": "Rafael"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/taneli-lahtinen-bXxnwBXVjVc-unsplash.jpg",
        "author": "Taneli"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/wilson-chen-t3ENXQ834jI-unsplash.jpg",
        "author": "Wilson"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/alfred-kenneally-UIu4RmMxnHU-unsplash.jpg",
        "author": "Alfred"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/mikita-yo-BZJYpZI2S0w-unsplash.jpg",
        "author": "Mikita"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/kateryna-moskalova-z1HRkVNhv18-unsplash.jpg",
        "author": "Kateryna"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/ika-abuladze-7xQnc4IE9I8-unsplash.jpg",
        "author": "Ika"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/vladislav-nikonov-VbgjucuER3Q-unsplash.jpg",
        "author": "Vladislav"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/nandkumar-patel-2YYO8HK_zqA-unsplash.jpg",
        "author": "Nandkumar"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/ks-kyung-gjuJr-T9alQ-unsplash.jpg",
        "author": "Ks"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/marcus-dietachmair-M7WlI-YPWt0-unsplash.jpg",
        "author": "Marcus"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/andrin-schranz-Le0Pg7P0hjU-unsplash.jpg",
        "author": "Andrin"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/carlos-costa-nvYdRcdCcy4-unsplash.jpg",
        "author": "Carlos"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/ivan-borinschi-HtlPQ9mIeZc-unsplash.jpg",
        "author": "Ivan"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/from-marwool-36zAXdOPQWQ-unsplash.jpg",
        "author": "From"
      },
      {
        "category": "PIGEON",
        "path": "pigeon/lenstravelier-0jGBtKkZ-MA-unsplash.jpg",
        "author": "Lenstravelier"
      },
      {
        "category": "EAGLE",
        "path": "eagle/zdenek-machacek-lOYyakxnMu0-unsplash.jpg",
        "author": "Zdenek"
      },
      {
        "category": "EAGLE",
        "path": "eagle/alfred-kenneally-69JBZWDa1r8-unsplash.jpg",
        "author": "Alfred"
      },
      {
        "category": "EAGLE",
        "path": "eagle/nick-fewings-6ZXGxk06Bng-unsplash.jpg",
        "author": "Nick"
      },
      {
        "category": "EAGLE",
        "path": "eagle/zdenek-machacek-bun7ERlQamw-unsplash.jpg",
        "author": "Zdenek"
      },
      {
        "category": "EAGLE",
        "path": "eagle/kev-kindred-QPnHX7yvJyM-unsplash.jpg",
        "author": "Kev"
      },
      {
        "category": "EAGLE",
        "path": "eagle/athanasios-papazacharias-bix-AqFSNVo-unsplash.jpg",
        "author": "Athanasios"
      },
      {
        "category": "EAGLE",
        "path": "eagle/james-lee-I2k9kks2XW8-unsplash.jpg",
        "author": "James"
      },
      {
        "category": "EAGLE",
        "path": "eagle/keith-martin-nnZWkX7_mqk-unsplash.jpg",
        "author": "Keith"
      },
      {
        "category": "EAGLE",
        "path": "eagle/lucas-rosin-7ffZeg03YAI-unsplash.jpg",
        "author": "Lucas"
      },
      {
        "category": "EAGLE",
        "path": "eagle/janet-ON4kvuxyMjo-unsplash.jpg",
        "author": "Janet"
      },
      {
        "category": "EAGLE",
        "path": "eagle/janmejaysinh-jadeja-3mYr6giGyZM-unsplash.jpg",
        "author": "Janmejaysinh"
      },
      {
        "category": "EAGLE",
        "path": "eagle/cristofer-maximilian-IYtp7I_yfIY-unsplash.jpg",
        "author": "Cristofer"
      },
      {
        "category": "EAGLE",
        "path": "eagle/mark-de-jong--drNFrdcd_Y-unsplash.jpg",
        "author": "Mark"
      },
      {
        "category": "EAGLE",
        "path": "eagle/photoholgic-F35yZlpccdY-unsplash.jpg",
        "author": "Photoholgic"
      },
      {
        "category": "EAGLE",
        "path": "eagle/elisa-stone-5uiiNj_S7n4-unsplash.jpg",
        "author": "Elisa"
      },
      {
        "category": "EAGLE",
        "path": "eagle/alvaro-postigo-dBwB8OOg45k-unsplash.jpg",
        "author": "Alvaro"
      },
      {
        "category": "EAGLE",
        "path": "eagle/alfred-kenneally-UsgLeLorRuM-unsplash.jpg",
        "author": "Alfred"
      },
      {
        "category": "EAGLE",
        "path": "eagle/peter-burdon-HRCjTprs034-unsplash.jpg",
        "author": "Peter"
      },
      {
        "category": "EAGLE",
        "path": "eagle/susanne-karl-5Id-tBbA3Ys-unsplash.jpg",
        "author": "Susanne"
      },
      {
        "category": "EAGLE",
        "path": "eagle/jeremy-hynes-zXDw1TqWLKs-unsplash.jpg",
        "author": "Jeremy"
      },
      {
        "category": "EAGLE",
        "path": "eagle/ingo-doerrie-i-YBTmZpNKw-unsplash.jpg",
        "author": "Ingo"
      },
      {
        "category": "EAGLE",
        "path": "eagle/kev-kindred-NMrCMfpYYCY-unsplash.jpg",
        "author": "Kev"
      },
      {
        "category": "EAGLE",
        "path": "eagle/peter-scholten-pVvBmRnT5yg-unsplash.jpg",
        "author": "Peter"
      },
      {
        "category": "EAGLE",
        "path": "eagle/ingo-doerrie-n3hjUhYoAGk-unsplash.jpg",
        "author": "Ingo"
      },
      {
        "category": "EAGLE",
        "path": "eagle/richard-lee-0NmTMg7dEA4-unsplash.jpg",
        "author": "Richard"
      },
      {
        "category": "EAGLE",
        "path": "eagle/ruben-zavala-uXe53aixu90-unsplash.jpg",
        "author": "Ruben"
      },
      {
        "category": "OWL",
        "path": "owl/edson-junior-_oaqIsLL5AA-unsplash.jpg",
        "author": "Edson"
      },
      {
        "category": "OWL",
        "path": "owl/cliff-johnson-F0WE_8VIIo8-unsplash.jpg",
        "author": "Cliff"
      },
      {
        "category": "OWL",
        "path": "owl/craig-hughes-9nGcUIIxyBQ-unsplash.jpg",
        "author": "Craig"
      },
      {
        "category": "OWL",
        "path": "owl/bruno-van-der-kraan-TkQjNx6qCTA-unsplash.jpg",
        "author": "Bruno"
      },
      {
        "category": "OWL",
        "path": "owl/angus-gray-pcjnWrsZ4TI-unsplash.jpg",
        "author": "Angus"
      },
      {
        "category": "OWL",
        "path": "owl/brendon-van-zyl-JFKhrtQbZJY-unsplash.jpg",
        "author": "Brendon"
      },
      {
        "category": "OWL",
        "path": "owl/ahmed-badawy-R4-DtoeKcHA-unsplash.jpg",
        "author": "Ahmed"
      },
      {
        "category": "OWL",
        "path": "owl/harm-weustink-gdBXlLO53N4-unsplash.jpg",
        "author": "Harm"
      },
      {
        "category": "OWL",
        "path": "owl/meg-jerrard-8nY0IUPIq5M-unsplash.jpg",
        "author": "Meg"
      },
      {
        "category": "OWL",
        "path": "owl/adriano-pinto-j4VUYdQJEj8-unsplash.jpg",
        "author": "Adriano"
      },
      {
        "category": "OWL",
        "path": "owl/slava-stupachenko-6aXMNgXw-50-unsplash.jpg",
        "author": "Slava"
      },
      {
        "category": "OWL",
        "path": "owl/ronan-furuta-8hIErEH5pr0-unsplash.jpg",
        "author": "Ronan"
      },
      {
        "category": "OWL",
        "path": "owl/ray-hennessy-n6I2GT_Pij4-unsplash.jpg",
        "author": "Ray"
      },
      {
        "category": "OWL",
        "path": "owl/nick-fewings-EA6GdDIWyII-unsplash.jpg",
        "author": "Nick"
      },
      {
        "category": "OWL",
        "path": "owl/joshua-j-cotten-Iqu-fD9cd1M-unsplash.jpg",
        "author": "Joshua"
      },
      {
        "category": "OWL",
        "path": "owl/kevin-mueller-xvwZJNaiRNo-unsplash.jpg",
        "author": "Kevin"
      },
      {
        "category": "OWL",
        "path": "owl/klaus-kreuer-r-V34grys7o-unsplash.jpg",
        "author": "Klaus"
      },
      {
        "category": "OWL",
        "path": "owl/james-armes-KzlaLG3RWYI-unsplash.jpg",
        "author": "James"
      },
      {
        "category": "OWL",
        "path": "owl/eduardo-bergen-ASJkBS8_ZvQ-unsplash.jpg",
        "author": "Eduardo"
      },
      {
        "category": "OWL",
        "path": "owl/zdenek-machacek-oqYHtXrLXLo-unsplash.jpg",
        "author": "Zdenek"
      },
      {
        "category": "OWL",
        "path": "owl/jessy-paston-5m5keAtrNm4-unsplash.jpg",
        "author": "Jessy"
      },
      {
        "category": "OWL",
        "path": "owl/jongsun-lee-OABoJYcLNrQ-unsplash.jpg",
        "author": "Jongsun"
      },
      {
        "category": "OWL",
        "path": "owl/dirk-van-wolferen-tpxnuebsy28-unsplash.jpg",
        "author": "Dirk"
      },
      {
        "category": "OWL",
        "path": "owl/keith-lazarus-sPZXWoWHqX8-unsplash.jpg",
        "author": "Keith"
      }
    ], status: :ok
  end

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
    guest = nil

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

    # Add extra information for OTP signup and delete the OTP record
    if is_otp_auth
      AuthProvider.create!(
        user: user,
        auth_provider: :auth_provider_password,
        metadata: { method: :otp },
      )
      otp_object.destroy
    else
      # Include additional details for guest signup then destroy the stale guest record
      if guest.present?
        if guest.result
          result = Result.new(ActiveSupport::JSON.decode(guest.result.to_json))
          result.user = user
          result.save!
        end

        AuthProvider.create!(
          user: user,
          auth_provider: :auth_provider_password,
          metadata: { method: :result }
        )
        guest.destroy
      end
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

    if user.user_type == :content_support
      raise Errors::AuthenticationError.new(message: "You cannot login as a content support user here, please use the support login page")
    end

    begin
      if user && user.authenticate(login_params[:password])
        access_token = create_access_token(user)
        refresh_token = create_refresh_token(user)

        render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }
      else
        raise Errors::AuthenticationError.new(message: "Incorrect login details")
      end
    rescue BCrypt::Errors::InvalidHash
      raise Errors::AuthenticationError.new(message: "Please login with another method or reset your password")
    end
  end

  def login_content_support
    email_or_username = login_params[:user_identity].downcase
    is_email = email_or_username.include? "@"

    if is_email
      raise Errors::AuthenticationError.new(message: "Email does not exist") unless User.exists?(email: email_or_username)
    else
      raise Errors::AuthenticationError.new(message: "User does not exist") unless User.exists?(username: email_or_username)
    end

    user = is_email ? User.find_by(email: email_or_username) : User.find_by(username: email_or_username)

    if !(user.user_type == :content_support || user.user_type == :admin)
      raise Errors::AuthenticationError.new(message: "You are not a content support user, please use the normal login page")
    end

    if user && user.authenticate(login_params[:password])
      access_token = create_access_token(user)
      refresh_token = create_refresh_token(user)

      render json: { data: user.serialized_user.merge({ "access_token": access_token, "refresh_token": refresh_token }) }
    else
      raise Errors::AuthenticationError.new(message: "Incorrect login details")
    end
  end

  def google_oauth
    token = params[:code]

    conn = Faraday.new(
      url: "https://oauth2.googleapis.com",
      headers: { 'Content-Type' => 'application/json' }
    )

    post_data = {
      code: token,
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"],
      grant_type: :authorization_code
    }

    token_response = conn.post("/token") do |req|
      req.body = post_data.to_json
    end

    logger.info token_response

    token_data = JSON.parse(token_response.body)
    access_token = token_data['access_token']
    id_token = token_data['id_token']

    conn2 = Faraday.new(
      url: "https://www.googleapis.com",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{id_token}"
      }
    )

    profile_response = conn2.get("/oauth2/v1/userinfo?alt=json&access_token=#{access_token}")
    profile_data = JSON.parse(profile_response.body)

    logger.info profile_data

    email = profile_data["email"]
    avatar = profile_data["picture"]

    user = User.find_by(email: email)

    if user
      # If the user already exists, check if an auth provider with google exists
      auth_provider = AuthProvider.find_by(user: user, auth_provider: :auth_provider_google)

      # If it doesn't exist, create it
      if !auth_provider
        AuthProvider.create!(
          user: user,
          auth_provider: :auth_provider_google,
          metadata: { avatar: avatar }
        )
      end

      first_time = false

    else # Create a new user

      # Get the username from the email and limit it to 20 characters
      username = email.split('@')[0][0..19]
      # Check if the username already exists
      if User.exists?(username: username)
        # If it exists, append a random 4 digit number to the end of the username
        username = username + rand(1000..9999).to_s
      end

      # Get necessary details from the profile data
      first_name = profile_data["given_name"]
      last_name = profile_data["family_name"]

      user = User.new(
        username: username,
        email: email,
        first_name: first_name,
        last_name: last_name,
        creator: false,
      )

      # Indicate that the user is in the oauth creation flow to allow creation of the user without a password
      user.in_oauth_creation_flow = true

      # Build the auth provider (this will be saved when the NEW user is saved; auto-saving of associations)
      user.auth_providers.build(
        user: user,
        auth_provider: :auth_provider_google,
        metadata: { avatar: avatar }
      )

      first_time = true
    end

    user.save!

    access_token = create_access_token(user)
    refresh_token = create_refresh_token(user)

    redirect_to "#{ENV['URL']}/google-auth/callback?access_token=#{access_token}&refresh_token=#{refresh_token}&first_time=#{first_time}"
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

    # Create a new auth provider with password if the user doesn't have one
    auth_provider = AuthProvider.find_by(user: user, auth_provider: :auth_provider_password)
    if !auth_provider
      AuthProvider.create!(
        user: user,
        auth_provider: :auth_provider_password,
        metadata: { method: :otp },
      )
    end

    # Indicate that the user is in the reset password flow to mandate password validation
    user.in_reset_password_flow = true

    user.update_attributes!(
      password: reset_password_params[:password],
      password_confirmation: reset_password_params[:password_confirmation]
    )

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
