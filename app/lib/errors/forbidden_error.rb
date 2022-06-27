module Errors
  class ForbiddenError < BaseError
    def initialize(message: nil, action: nil, status: nil, source: nil, data: nil)
      super(
        message: message || "Not Authorized",
        status: status || 403,
        source: source,
        data: data,
      )
    end
  end
end
