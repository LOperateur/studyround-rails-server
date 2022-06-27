module Errors
  class AuthorizationError < BaseError
    def initialize(message: nil, action: nil, status: nil, source: nil, data: nil)
      super(
        message: message || "You need to sign in",
        status: status || 401,
        source: source,
        data: data,
      )
    end
  end
end