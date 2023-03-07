module ErrorHandler
  extend ActiveSupport::Concern

  ERRORS = {
      'ActiveRecord::RecordNotFound' => 'Errors::NotFoundError',
      'ActiveRecord::RecordInvalid' => 'Errors::InvalidError',

      'Errors::AuthenticationError' => 'Errors::AuthenticationError',
      'Errors::AuthorizationError' => 'Errors::AuthorizationError',
      'Errors::BaseError' => 'Errors::BaseError',
      'Errors::ForbiddenError' => 'Errors::ForbiddenError',
  }

  included do
    rescue_from(StandardError, with: lambda { |e| handle_error(e) })
  end

  private

  def handle_error(e)
    mapped_error = map_error(e)

    # Default to Base Error if not mapped
    mapped_error ||= Errors::BaseError.new

    # Add a message if there's one available
    mapped_error.message = e.message if e.message.present?

    # If it's a not-found error, simplify the error message by removing the params after "with"
    if mapped_error.is_a? Errors::NotFoundError
      mapped_error.message = mapped_error.message.split(" with").first
    end

    # If it's an invalid error, add the record's errors to the mapped error
    if mapped_error.is_a? Errors::InvalidError
      mapped_error.errors = e.record.errors.to_h if (mapped_error.errors.blank? && e.record.present? && e.record.errors.present?)
    end

    render_error(mapped_error)
  end

  def map_error(e)
    error_klass = e.class.name
    return e if ERRORS.values.include?(error_klass)
    ERRORS[error_klass]&.constantize&.new
  end

  def render_error(error)
    render json: { errors: error.to_h }, status: error.status
  end
end