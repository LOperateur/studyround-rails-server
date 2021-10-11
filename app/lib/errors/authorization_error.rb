module Errors
  class AuthorizationError < BaseError
    def initialize(message: nil, action: nil, status: nil, source: {})
      super(
        message: message || "Not Authorized",
        status: status || 403
      )
    end
  end
end
