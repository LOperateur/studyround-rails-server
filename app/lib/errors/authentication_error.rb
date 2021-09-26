module Errors
  class AuthenticationError < BaseError
    def initialize(message: nil, action: nil, status: nil, data: {})
      super(
        message: message || "Unprocessable Entity",
        status: status || 422
      )
    end
  end
end
