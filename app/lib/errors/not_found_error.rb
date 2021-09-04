module Errors
  class NotFoundError < BaseError
    def initialize(message: nil, action: nil, status: nil, data: {})
      super(
          message: message || "This item could not be found",
          status: 404
      )
    end
  end
end
