class HealthCheckController < ApplicationController
  skip_before_action :authorize!

  def index
    render json: { status: 'ok' }, status: :ok
  end
end
