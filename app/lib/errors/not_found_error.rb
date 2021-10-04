module Errors
  class NotFoundError < BaseError
    def initialize(message: nil, action: nil, status: nil, source: {})
      super(
          message: message || "This item could not be found",
          status: 404,
          source: { pointer: "/request/url/:id" }
      )
    end
  end
end
