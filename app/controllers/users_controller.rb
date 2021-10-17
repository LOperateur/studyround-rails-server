class UsersController < ApplicationController
  wrap_parameters format: []

  def show
    render json: User.find(params[:id]), root: :data
  end
end
