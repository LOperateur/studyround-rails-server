class JsonWebToken
  class << self
    def encode(payload, exp = 1.day.from_now)
      payload[:exp] = exp.to_i
      # JWT.encode(payload, Rails.application.secret_key_base)
      JWT.encode(payload, Rails.application.credentials.dig(Rails.env.to_sym, :secret_key_base))
    end

    def decode(token)
      # body = JWT.decode(token, Rails.application.secret_key_base)[0]
      body = JWT.decode(token, Rails.application.credentials.dig(Rails.env.to_sym, :secret_key_base))[0]
      HashWithIndifferentAccess.new body
    rescue
      nil
    end
  end
end