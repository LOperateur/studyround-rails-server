module Errors
  class InvalidError < ::StandardError
    def initialize(errors = {})
      @errors = errors
      @status = 422
      @message = "Unprocessable entity"
    end

    def to_h
      errors.reduce([]) do |r, (att, msg)|
        r << {
          status: status,
          message: msg,
          source: { pointer: "/data/attributes/#{att}" }
        }
      end
    end

    attr_accessor :status, :message

    private

    attr_reader :errors
  end
end
