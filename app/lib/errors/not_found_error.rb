module Errors
  class NotFoundError < BaseError
    def initialize(message: nil, action: nil, source: nil, data: nil)
      super(
        message: message || "This item could not be found",
        status: 404,
        action: action,
        source: source || { pointer: "/request/url/:id" },
        data: data,
      )
    end
  end
end
