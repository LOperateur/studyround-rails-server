module Errors
  class AuthorizationError < BaseError
    def initialize(message: nil, action: nil, status: nil, data: {})
      super(
          message: message || "Not Authorized",
          status: 403
      )
    end
  end
end