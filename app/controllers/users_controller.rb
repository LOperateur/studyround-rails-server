class UsersController < ApplicationController
  # Todo: Call authorize
  def show
    render json: User.find(params[:id]), root: :data
  end
end
