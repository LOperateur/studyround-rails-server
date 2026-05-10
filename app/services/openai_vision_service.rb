class OpenaiVisionService
  MODEL = "gpt-5.2"

  def initialize(message:, images: [])
    @message = message
    @images = images || []
  end

  def call
    client = OpenAI::Client.new
    response = client.responses.create(parameters: { model: MODEL, input: build_input })
    answer = response.dig("output", 0, "content", 0, "text")
    { answer: answer }
  rescue Faraday::Error => e
    raise Errors::BaseError.new(message: "AI service unavailable", status: 502)
  end

  private

  def build_input
    return @message unless @images.any?

    content = [{ type: "input_text", text: @message }]
    @images.each do |url|
      content << { type: "input_image", image_url: url, detail: "high" }
    end
    [{ role: "user", content: content }]
  end
end
