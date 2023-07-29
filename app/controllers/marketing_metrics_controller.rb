class MarketingMetricsController < ApplicationController
  def source
    conn = Faraday.new(
      url: ENV["MARKETING_METRICS_ENDPOINT"],
      headers: { 'Content-Type' => 'application/json' }
    )
    post_data = { username: current_user.username, source: params[:source] }
    response = conn.post("/v1/marketing-source") do |req|
      req.body = { username: current_user.username, source: params[:source] }.to_json
    end

    render json: response.body
  end
end
