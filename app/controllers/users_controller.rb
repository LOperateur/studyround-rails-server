class UsersController < ApplicationController
  wrap_parameters format: []

  def show
    render json: User.find(params[:id]), root: :data
  end

  def profile
    render json: current_user, root: :data
  end

  def update
    profile_params = prepare_received_profile_params(update_profile_params)
    handle_image_update(profile_params)
    current_user.assign_attributes(profile_params.except(:profile_image_url))

    begin
      current_user.save!
      render json: current_user, root: :data, meta: { message: "User updated successfully" }
    rescue ActiveRecord::RecordInvalid
      raise Errors::InvalidError.new(current_user.errors.to_h)
    end
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

  def prepare_received_profile_params(received_params)
    profile_params = received_params

    if received_params.key?(:date_of_birth)
      date_of_birth = Date.parse(received_params[:date_of_birth])
      profile_params[:date_of_birth] = date_of_birth
    end

    return profile_params
  end

  # Image handling in controller during update
  # 1.) image √   image_url √   =>    Changing image
  # 2.) image √   image_url X   =>    New image
  # 3.) image X   image_url √   =>    No changes
  # 4.) image X   image_url X   =>    Deleting image
  def handle_image_update(profile_params)
    has_image_to_upload = profile_params[:profile_image].present?
    has_image_url_to_retain = profile_params[:profile_image_url].present?

    if has_image_to_upload
      # Attach is handled in `assign_attributes` for new or changed image.
      # Deleting any current image first is automatically handled by Active Storage.
    else
      if has_image_url_to_retain
        # No changes, do nothing
      else
        # Delete image
        current_user.profile_image.purge
      end
    end
  end

  def update_profile_params
    params.permit(:first_name, :last_name, :other_name, :date_of_birth, :creator,
                  :pro_account, :occupation, :about, :country, :profile_image, :profile_image_url)
  end

  def create_interests_params
    params.permit(:category_ids => [])
  end
end
