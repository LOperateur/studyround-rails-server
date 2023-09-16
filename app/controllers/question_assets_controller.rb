class QuestionAssetsController < ApplicationController
  before_action :load_creator_course

  wrap_parameters format: []

  def index
    asset_type_filter = params[:asset_type]&.to_sym

    case asset_type_filter
    when :passage
      question_assets = @course.question_assets.where(asset_type: :asset_type_passage)
    when :image
      question_assets = @course.question_assets.where(asset_type: :asset_type_image)
    else
      question_assets = @course.question_assets
    end

    paginated_assets = paginate(question_assets.order(created_at: :asc), params)
    render json: paginated_assets, root: :data, meta: paginated_meta(paginated_assets), status: :ok
  end

  def create
    if @course.test && @course.publish_status_published?
      raise Errors::ForbiddenError.new(message: "You cannot create new question assets for a published test.")
    end

    question_asset = @course.question_assets.build

    if create_question_asset_params[:asset_type] == "passage"
      question_asset.assign_attributes(
        name: create_question_asset_params[:name],
        asset_type: :asset_type_passage,
        content: create_question_asset_params[:content],
      )
    elsif create_question_asset_params[:asset_type] == "image"
      question_asset.assign_attributes(
        name: create_question_asset_params[:name],
        asset_type: :asset_type_image,
      )
      question_asset.file.attach(create_question_asset_params[:file])
    else
      raise Errors::BaseError.new(message: "Invalid asset type", status: 400)
    end

    # Identify the original creator
    question_asset.creator_id = current_user.id

    question_asset.save!

    render json: question_asset, root: :data, status: :created
  end

  def update
    if @course.test && @course.publish_status_published?
      raise Errors::ForbiddenError.new(message: "You cannot edit question assets for a published test.")
    end

    question_asset = @course.question_assets.find(params[:id])

    question_asset.assign_attributes(name: update_question_asset_params[:name])

    if question_asset.asset_type_passage? && update_question_asset_params[:content].present?
      question_asset.assign_attributes(content: update_question_asset_params[:content])
    elsif question_asset.asset_type_image? && update_question_asset_params[:file].present?
      # ActiveStorage will automatically purge the old file
      question_asset.file.attach(update_question_asset_params[:file])
    else
      # Raise errors for invalid asset matching
      if (question_asset.asset_type_passage? && update_question_asset_params[:file].present?) ||
        (question_asset.asset_type_image? && update_question_asset_params[:content].present?)
        raise Errors::BaseError.new(message: "Invalid asset configuration", status: 400)
      end
    end

    question_asset.save!

    render json: question_asset, root: :data, status: :ok
  end

  def show
    question_asset = @course.question_assets.find(params[:id])
    render json: question_asset, root: :data, status: :ok
  end

  def destroy
    if @course.test && @course.publish_status_published?
      raise Errors::ForbiddenError.new(message: "You cannot make question asset changes to a published test.")
    end

    question_asset = @course.question_assets.find(params[:id])

    begin
      question_asset.destroy!
    rescue ActiveRecord::DeleteRestrictionError
      raise Errors::BaseError.new(message: "Cannot delete question asset that is in use", status: 400)
    end

    render json: question_asset, root: :data, status: :ok
  end

  private

  def load_creator_course
    @course = Course.non_deleted_courses.find(params[:course_id])

    # Todo: Add roles and permissions check for destroy-own

    # Mapping roles to their allowed methods
    roles_and_methods = {
      :admin => [:index, :show, :create, :update, :destroy],

      :creator => [:index, :show, :create, :update, :destroy],

      :role_co_creator => [:index, :show, :create, :update, :destroy],

      :role_editor => [:index, :show, :create, :update, :destroy],
    }

    # Check the user level/role and permissions
    # Special case to distinguish between an admin who is not the creator and admin who is also the creator
    # Since it is possible for some permissions to only be granted to the creator not the admin.
    if current_user.user_type == :admin && @course.creator != current_user
      if !roles_and_methods[:admin].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    elsif @course.creator == current_user
      if !roles_and_methods[:creator].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    elsif CourseCollaborator.where(user: current_user, course: @course).exists?
      role = CourseCollaborator.where(user: current_user, course: @course).role.to_sym
      if !roles_and_methods[role].include?(action_name.to_sym)
        raise Errors::ForbiddenError.new(message: "You don't have the authority to perform this action.")
      end
    else
      raise Errors::ForbiddenError.new(message: "You don't have the authority to manage the question assets in this course.")
    end
  end

  def create_question_asset_params
    params.permit(:asset_type, :name, :content, :file)
  end

  def update_question_asset_params
    params.permit(:content, :name, :file)
  end

end
