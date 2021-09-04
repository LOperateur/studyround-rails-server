module Errors
  class BaseError < ::StandardError
    def initialize(message: nil, action: nil, status: nil, data: {})
      @message = message || "We encountered an unexpected error, but our developers have been already notified about it"
      @action = action || :nothing
      @status = status || 500
      @data = data.deep_stringify_keys
    end

    def to_h
      {
          status: status,
          message: message,
          action: action,
          data: data
      }
    end

    def serializable_hash
      to_h
    end

    def to_s
      to_h.to_s
    end

    attr_accessor :status, :message, :action, :data
    # attr_accessor :message
  end
end