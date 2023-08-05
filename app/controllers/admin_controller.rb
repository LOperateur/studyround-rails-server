class AdminController < ApplicationController
  before_action :check_admin

  wrap_parameters format: []

  def users
    user_type_filter = params[:user_type]&.to_sym

    # Bare-bones implementation of filtering by user type
    # Todo: Implement better access permission levels
    case user_type_filter
    when :admin
      users = User.active_users.where("email LIKE ?", "admin%@myulearn.com")
    when :content_support
      users = User.active_users.where("email LIKE ?", "content%@myulearn.com")
    when :standard
      users = User.active_users.where("email NOT LIKE ? AND email NOT LIKE ?", "admin%@myulearn.com", "content%@myulearn.com")
    else
      users = User.active_users.all
    end

    paginated_users = paginate(users.order(created_at: :asc), params)
    render json: paginated_users, root: :data, meta: paginated_meta(paginated_users), each_serializer: ProfileSerializer
  end

  def suspend_user
    user = User.non_deleted_users.find(suspend_user_params[:user_id])
    if suspend_user_params[:remove_suspension] == true
      user.user_status_active!
      message = "Suspension lifted!"
    else
      user.user_status_suspended!
      message = "Suspension placed on user!"
    end
    render json: user, root: :data, status: :ok, meta: { message: message }
  end

  def delete_user
    user = User.non_deleted_users.find(delete_user_params[:user_id])
    user.user_status_deleted!
    render json: user, root: :data, status: :ok, meta: { message: "User deleted!" }
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

  def merge_courses
    main_course = Course.non_deleted_courses.find(merge_courses_params[:main_course_id])
    merge_course = Course.non_deleted_courses.find(merge_courses_params[:merge_course_id])

    if merge_course.test || main_course.test
      raise Errors::BaseError.new(message: "Tests cannot be merged", status: 400)
    end

    # Check if the merge course has been published previously
    if merge_course.last_publish_date.present?
      raise Errors::BaseError.new(message: "You cannot merge in a course that has been published", status: 400)
    end

    # Check question counts
    if main_course.questions.non_deleted_questions.count == 0
      raise Errors::BaseError.new(message: "The course you want to merge to has no questions", status: 400)
    end

    if merge_course.questions.non_deleted_questions.count == 0
      raise Errors::BaseError.new(message: "The course you want to merge has no questions", status: 400)
    end

    # Now attempt to merge the courses by moving the questions
    # Start a transaction to ensure that all operations are atomic
    ApplicationRecord.transaction do
      last_main_course_question =
        main_course.questions.non_deleted_questions.find_by!(course_id: main_course.id, next_id: nil)

      first_merge_course_question =
        merge_course.questions.non_deleted_questions.find_by!(course_id: merge_course.id, previous_id: nil)

      # Update the last question of the main course to point to the first question of the merge course
      last_main_course_question.update!(next_id: first_merge_course_question.id)

      # Update the first question of the merge course to point to the last question of the main course
      first_merge_course_question.update!(previous_id: last_main_course_question.id)

      # Move the questions to the main course
      Question.where(course_id: merge_course.id).update_all(course_id: main_course.id)

      # Delete the merged course
      merge_course.destroy!
    end

    render json: main_course, root: :data, status: :ok
  end

  def suspend_course
    course = Course.non_deleted_courses.find(suspend_course_params[:course_id])
    if course.test && course.course_status_closed?
      raise Errors::BaseError.new(message: "This Test is over! Further action cannot be taken", status: 400)
    end

    if suspend_course_params[:remove_suspension] == true
      # Firstly check if the test is expired
      if course.test
        expired = Time.now > course.test_expiration
        if expired
          course.course_status_expired!
          raise Errors::BaseError.new(message: "This Test is now expired!", status: 400)
        end
      end

      course.course_status_active!
      message = "Suspension lifted!"
    else
      course.course_status_suspended!
      message = "Suspension placed on Course!"
    end

    render json: course, root: :data, status: :ok, meta: { message: message }
  end

  # This method is used to approve a user as a creator. It is called when the admin
  # wants to manually approve the creator request. This differs from the automatic approval
  # that happens when `/user/creator-consent` is called by the user but they
  # ultimately do the same thing.
  def approve_creator
    user = User.find(approve_creator_params[:user_id])
    if !user.creator
      # Update the user's creator status indicating they can create content
      user.update!(creator: true)

      if approve_creator_params[:primary_creator] == true
        # Update the user's metadata indicating they are a primarily a creator
        metadata = user.metadata || {}
        user.update!(metadata: metadata.merge({ primary_creator: true }))
      end

      # Send an email to the user to confirm their creator's consent
      UserMailer.with(email: user.email).creator_consent_email.deliver_later
    end

    render json: user, root: :data, status: :ok
  end

  private

  def check_admin
    if current_user.user_type != :admin
      raise Errors::ForbiddenError.new(message: "You are not authorized to perform this action")
    end
  end

  def suspend_user_params
    params.permit(:user_id, :remove_suspension)
  end

  def delete_user_params
    params.permit(:user_id)
  end

  def assign_course_params
    params.permit(:course_id, :user_id)
  end

  def merge_courses_params
    params.permit(:main_course_id, :merge_course_id)
  end

  def suspend_course_params
    params.permit(:course_id, :remove_suspension)
  end

  def approve_creator_params
    params.permit(:user_id, :primary_creator)
  end
end
