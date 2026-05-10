class OpenaiVisionService
  MODEL = "gpt-5.2"

  def initialize(message:, images: [])
    @message = message
    @images = images || []
  end

  def call
    client = OpenAI::Client.new
    response = client.chat(parameters: { model: MODEL, messages: [build_message] })
    answer = response.dig("choices", 0, "message", "content")
    { answer: answer }
  rescue Faraday::Error => e
    raise Errors::BaseError.new(message: "AI service unavailable", status: 502)
  end

  private

  def build_message
    { role: "user", content: @images.any? ? content_array : @message }
  end

  def content_array
    parts = [{ type: "text", text: @message }]
    @images.each do |url|
      parts << { type: "image_url", image_url: { url: url, detail: "high" } }
    end
    parts
  end
end
