module Errors
  class BaseError < ::StandardError
    def initialize(message: nil, action: nil, status: nil, source: nil, data: nil)
      @message = message || "Something went wrong :("
      @action = action || :nothing
      @status = status || 500
      @source = source.nil? ? nil : source.deep_stringify_keys
      @data = data.nil? ? nil : data.deep_stringify_keys
    end

    def to_h
      [{
         status: status,
         message: message,
         action: action,
         source: source,
         data: data,
       }.compact]
    end

    def serializable_hash
      to_h
    end

    def to_s
      to_h.to_s
    end

    attr_accessor :status, :message, :action, :source, :data
  end
end