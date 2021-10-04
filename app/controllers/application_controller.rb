class ApplicationController < ActionController::API
  include ErrorHandler

  def index
    render json: {}
  end
end
