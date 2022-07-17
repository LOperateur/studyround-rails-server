module Errors
  class AuthenticationError < BaseError
    def initialize(message: nil, action: nil, status: nil, source: nil, data: nil)
      super(
        message: message || "Unprocessable Entity",
        status: status || 422,
        action: action,
        source: source,
        data: data,
      )
    end
  end
end
