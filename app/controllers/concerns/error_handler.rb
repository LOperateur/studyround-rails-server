module ErrorHandler
  extend ActiveSupport::Concern

  ERRORS = {
      'ActiveRecord::RecordNotFound' => 'Errors::NotFoundError',
      'ActiveRecord::RecordInvalid' => 'ActiveRecord::RecordInvalid',
      'Errors::AuthorizationError' => 'Errors::AuthorizationError',
      'Errors::AuthenticationError' => 'Errors::AuthenticationError',
      'Errors::BaseError' => 'Errors::BaseError',
  }

  included do
    # rescue_from(StandardError, with: lambda { |e| handle_error(e) })
  end

  private

  def handle_error(e)
    mapped = map_error(e)
    # notify about unexpected_error unless mapped
    mapped ||= Errors::BaseError.new

    # add a message if there's one available
    # mapped.message = e.to_s unless e.to_s.blank?
    render_error(mapped)
  end

  def map_error(e)
    error_klass = e.class.name
    return e if ERRORS.values.include?(error_klass)
    ERRORS[error_klass]&.constantize&.new
  end

  def render_error(error)
    render json: { errors: [error.to_h] }, status: error.status
  end
end