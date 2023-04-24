class UsersController < ApplicationController
  include UserInterest

  wrap_parameters format: []

  def admin_index
    if current_user.user_type == :admin
      user_type_filter = params[:user_type]&.to_sym

      # Bare-bones implementation of filtering by user type
      # Todo: Implement better access permission levels
      case user_type_filter
      when :admin
        users = User.where("email = ?", "admin@myulearn.com")
      when :content_support
        users = User.where("email LIKE ?", "content%@myulearn.com")
      when :standard
        users = User.where("email != ? AND email NOT LIKE ?", "admin@myulearn.com", "content%@myulearn.com")
      else
        users = User.all
      end

      paginated_users = paginate(users.order(created_at: :asc), params)
      render json: paginated_users, root: :data, meta: paginated_meta(paginated_users), each_serializer: ProfileSerializer
    else
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

  def assign_course
    if current_user.user_type == :admin
      user = User.find(params[:user_id])
      course = Course.non_deleted_courses.find(params[:course_id])

      course.creator = user
      course.save!

      render json: course, root: :data, status: :ok
    else
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

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
    categories = create_interests_params[:category_ids]

    register_interest(current_user, categories)

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

  def assign_course_params
    params.permit(:course_id, :user_id)
  end
end
