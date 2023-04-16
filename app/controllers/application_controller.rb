class ApplicationController < ActionController::API
  include ErrorHandler
  include Paginable

  before_action :authorize!, except: [:endpoint_not_found]

  def index
    render json: {}
  end

  def endpoint_not_found
    raise Errors::NotFoundError.new(message: "This endpoint does not exist", source: { pointer: request.path })
  end

  private

  def http_auth_header_token
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
end
