require 'net/http'
require 'json'

class MarketingMetricsController < ApplicationController
  def source
    metrics_endpoint = ENV["MARKETING_METRICS_ENDPOINT"] + "/marketing-source"
    url = URI.parse(metrics_endpoint)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.path, { 'Content-Type' => 'application/json' })
    request.body = { username: current_user.username, source: params[:source] }.to_json

    response = http.request(request)
    data = JSON.parse(response.body)

    render json: data
  end
end
