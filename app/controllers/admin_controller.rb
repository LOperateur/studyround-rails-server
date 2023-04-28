class AdminController < ApplicationController
  before_action :check_admin

  wrap_parameters format: []

  def users
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
  end

  def courses
    if params[:creator_id].present?
      # Get courses by creator
      creator = User.find(params[:creator_id])
      courses = Course.non_deleted_courses.where(creator_id: creator.id)
    else
      # Just get all courses
      courses = Course.non_deleted_courses
    end

    paginated_courses = paginate(courses.order(created_at: :desc), params)
    render json: paginated_courses, root: :data, meta: paginated_meta(paginated_courses)
  end

  def assign_course
    user = User.find(params[:user_id])
    course = Course.non_deleted_courses.find(params[:course_id])

    course.creator = user
    course.save!

    render json: course, root: :data, status: :ok
  end

  private

  def check_admin
    if current_user.user_type != :admin
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

  def assign_course_params
    params.permit(:course_id, :user_id)
  end
end
