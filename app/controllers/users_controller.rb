class UsersController < ApplicationController
  wrap_parameters format: []

  def show
    render json: User.find(params[:id]), root: :data
  end

  def interests
    user = User.find(params[:user_id])

    categories = create_interests_params[:categories]
    categories.each do |category_id|
      interest = user.interests.build(category_id: category_id, affinity: 0)
      if interest
        interest.save!
      end
    end

    render json: {message: "Registered interest!"}, status: :created
  end

  private

  def create_interests_params
    params.permit(:categories) || ActionController::Parameters.new
  end
end
