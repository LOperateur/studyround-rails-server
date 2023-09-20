class AdminController < ApplicationController
  include CourseHelper

  before_action :check_admin
  before_action :default_12_page_size, only: [:courses]

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

    if params[:creator] == "true"
      users = users.where(creator: true)
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
    # Get all non-deleted courses
    courses = search_and_filter(Course.non_deleted_courses.order(created_at: :desc))

    paginated_courses = paginate(courses, params)
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

    # Now attempt to merge the courses by moving the questions and the assets
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

      # Move the assets to the main course
      QuestionAsset.where(course_id: merge_course.id).update_all(course_id: main_course.id)

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

  # This method is used to create a new creator user or approve an existing user as a creator.
  # It is called when the admin wants to manually create or approve the creator request.
  # This differs from the automatic approval that happens when `/user/creator-consent` is called by the user.
  def make_or_approve_creator
    email = approve_creator_params[:email]

    if User.exists?(email: email)
      # Email already exists, approve the user as a creator instead
      user = User.find_by!(email: email)

      if !user.creator
        # Update the user's creator status indicating they can create content
        user.update!(creator: true)

        # Send an email to the user to confirm their creator's consent
        UserMailer.with(email: user.email).creator_consent_email.deliver_later
      else
        raise Errors::BaseError.new(message: "User is already a creator", status: 400)
      end

      render json: user, root: :data, status: :ok, meta: { message: "User is now approved as a creator!" }

    else
      # User does not exist, create a new user

      # Extract username from email
      base_username = email.split('@').first
      # Sanitize username: remove invalid characters, then restrict length to 20 characters
      username = base_username.gsub(/[^-a-z0-9_.]/i, '').slice(0, 20)
      # Check if the username already exists
      if User.exists?(username: username)
        # If it exists, append a random 4 digit number to the end of the username
        username = username + rand(1000..9999).to_s
      end

      # Generate a random password for the user
      password = SecureRandom.hex(6)

      user = User.new(
        username: username,
        email: email,
        password: password,
        password_confirmation: password,
        creator: true,
        metadata: { primary_creator: true },
      )

      # Build the auth provider (this will be saved when the NEW user is saved; auto-saving of associations)
      user.auth_providers.build(
        user: user,
        auth_provider: :auth_provider_password,
        metadata: { method: :admin_creation }
      )

      user.save!

      # Send an email to the user to confirm their creator's consent
      UserMailer.with(email: user.email).creator_consent_email.deliver_later

      # Also send an email containing the user's credentials
      UserMailer.with(email: email, username: username, password: password).new_creator_email.deliver_later

      render json: user, root: :data, status: :created, meta: { message: "User created and approved as a creator!" }
    end

  end

  def reset_creator
    email = reset_creator_params[:email]

    if User.exists?(email: email)
      user = User.find_by!(email: email)

      if !user.creator
        raise Errors::BaseError.new(message: "User is not a creator", status: 400)
      end

      # Generate a random password for the user
      password = SecureRandom.hex(6)

      # Send an email containing the user's reset credentials
      UserMailer.with(email: email, username: user.username, password: password).new_creator_email.deliver_later

      # Create a new auth provider with password if the user doesn't have one
      auth_provider = AuthProvider.find_by(user: user, auth_provider: :auth_provider_password)
      if !auth_provider
        AuthProvider.create!(
          user: user,
          auth_provider: :auth_provider_password,
          metadata: { method: :admin_reset },
        )
      end

      # Indicate that the user is in the reset password flow to mandate password validation
      user.in_reset_password_flow = true

      user.update_attributes!(
        password: password,
        password_confirmation: password
      )

    else
      raise Errors::BaseError.new(message: "User with this email does not exist", status: 400)
    end

    render json: user, root: :data, status: :created, meta: { message: "User creator credentials are reset!" }
  end

  def temp_migrate_users
    admin_user = User.find_by(email: "admin@myulearn.com")
    admin_user.username = "studyround"
    admin_user.save!

    ulearn_users = User.where("email LIKE ?", "%@myulearn.com")

    ulearn_users.each do |ulearn_user|
      email = ulearn_user.email
      new_email = email.gsub("@myulearn.com", "@studyround.com")
      ulearn_user.update!(email: new_email)
    end

    render json: { message: "Users migrated successfully" }, status: :ok
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
    params.permit(:email)
  end

  def reset_creator_params
    params.permit(:email)
  end
end
