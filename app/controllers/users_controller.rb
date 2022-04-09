class UsersController < ApplicationController
  wrap_parameters format: []

  def show
    render json: User.find(params[:id]), root: :data
  end

  def profile
    render json: current_user, root: :data
  end

  def interested_categories
    render json: current_user.categories.order(affinity: :desc), root: :data
  end

  def create_interests
    user = current_user

    categories = create_interests_params[:category_ids]

    categories.each do |category_id|
      is_previously_interested = false

      # Check if the user is already interested in this category
      user.interests.each do |interest|
        if interest.category_id == category_id
          is_previously_interested = true
          # Limit affinity to 9 max
          interest.affinity = [interest.affinity + 1, 9].min
          interest.save!
        end
      end

      # If the user has not previously been interested in this category...
      unless is_previously_interested
        interest = user.interests.build(category_id: category_id, affinity: 0)
        if interest
          interest.save!
        end
      end
    end

    render json: { message: "Registered interest!" }, status: :created
  end

  private

  def create_interests_params
    params.permit(:category_ids => [])
  end
end
