class OpenaiRequestsController < ApplicationController
  wrap_parameters format: []

  def create
    message = params[:message]
    raise Errors::BaseError.new(message: "message is required", status: 422) if message.blank?

    images = params[:images] || []
    result = OpenaiVisionService.new(message: message, images: images).call
    render json: { data: result }, status: :ok
  end
end
