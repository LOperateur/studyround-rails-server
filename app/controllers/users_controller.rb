class UsersController < ApplicationController
  include UserInterest

  wrap_parameters format: []

  def show
    render json: User.non_deleted_users.find(params[:id]), root: :data
  end

  def show_current_user
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
    categories = create_interests_params[:category_ids]

    register_interest(current_user, categories)

    render json: { message: "Registered interest!" }, status: :created
  end

  def onboard
    onboarding_data = current_user.onboarding
    onboard_user_params.each do |key, value|
      onboarding_data[key] = value
    end

    # Todo: Also clean up the onboarding data in case we remove any fields
    current_user.update!(onboarding: onboarding_data)

    render json: current_user, root: :data
  end

  def creator_consent
    if !current_user.creator
      # Update the user's creator status indicating they can create content
      current_user.update!(creator: true)

      # Send an email to the user to confirm their creator's consent
      UserMailer.with(email: current_user.email).creator_consent_email.deliver_later
    end

    render json: current_user, root: :data
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
    params.permit(:first_name, :last_name, :other_name, :date_of_birth,
                  :pro_account, :occupation, :about, :country, :profile_image, :profile_image_url)
  end

  def create_interests_params
    params.permit(:category_ids => [])
  end

  def onboard_user_params
    # Get the permitted params from an ENV variable
    permitted_onboarding_params = ENV['ONBOARDING_PARAMS'].split('|').map(&:to_sym)
    params.permit(*permitted_onboarding_params)
  end
end
