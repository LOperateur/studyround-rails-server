class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ErrorHandler
  include Paginable

  # Cookie names used for auth. Kept here so controllers and helpers
  # share a single source of truth.
  ACCESS_TOKEN_COOKIE = :access_token
  REFRESH_TOKEN_COOKIE = :refresh_token

  before_action :authorize!, except: [:route_not_found]

  def index
    render json: {}
  end

  def route_not_found
    raise Errors::NotFoundError.new(message: "This route does not exist", source: { pointer: request.path })
  end

  private

  # Resolve the access token from (in order): the access_token cookie,
  # then the Authorization: Bearer <token> header.
  def http_auth_header_token
    cookie_token = cookies[ACCESS_TOKEN_COOKIE]
    return cookie_token if cookie_token.present?

    if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    else
      nil
    end
  end

  def decoded_auth_token
    @auth_token = JsonWebToken.decode(http_auth_header_token)
  end

  def current_user
    @current_user ||= User.find(decoded_auth_token[:user_id]) if decoded_auth_token && decoded_auth_token[:user_id]
    @current_user
  end

  def authorize!
    raise Errors::AuthorizationError unless current_user
  end

  # Add user_id to lograge payload
  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
  end

  # Helper method to default the page size to 12 if not specified
  # To use, add `before_action :default_12_page_size` to the controller
  def default_12_page_size
    params[:page_size] ||= 12
  end
end
