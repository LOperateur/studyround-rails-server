class TestsController < ApplicationController
  include ActionView::Helpers::DateHelper
  include SessionHelper
  include CourseHelper
  include TestHelper

  before_action :load_test, except: [:update_test_session, :verify_active_test_session, :halt_attempts, :close_test]
  before_action :load_creators_test, only: [:halt_attempts, :close_test]

  wrap_parameters format: []

  def test_instructions
    instructions_response = init_test_instructions(current_user, @course)

    render json: {
      data: instructions_response
    }
  end

  def start_test
    if @course.sale_status_paid? && !current_user.has_purchased_item(@course)
      raise Errors::ForbiddenError.new(message: "Please purchase this test before using it")
    end

    session_param = get_start_test_session(current_user, @course, start_test_session_params[:extra_id])
    is_randomized = @course.instructions['randomize_questions'] || false

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # If session_param already has an id, return the existing session, otherwise, create a new one
    session = session_param[:id].present? ? session_param : create_test_based_session(session_param)

    questions, paginated_metadata = if is_randomized
                                      published_active_random_questions(@course, params, session.id)
                                    else
                                      published_active_ordered_questions(@course, params)
                                    end
    render_session_data(session.serialized_session, questions, true, paginated_metadata)
  end

  def end_test
    result = get_end_test_result(
      current_user,
      @course,
      end_test_session_params[:session_items],
      end_test_session_params[:session_id]
    )

    render json: result, root: :data, serializer: SessionResultSerializer, status: :created
  end

  def questions
    @course = Course.non_deleted_courses.find(params[:course_id])

    session_param = get_start_test_session(current_user, @course)
    is_randomized = @course.instructions['randomize_questions'] || false

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # Existing session, simply assign it
    session = session_param

    # If session doesn't have an id, then it doesn't exist in the DB yet.
    if session[:id].blank?
      raise Errors::BaseError.new(message: "No existing session for this user. Please refresh or check your results", status: 400)
    end

    questions, paginated_metadata = if is_randomized
                                      published_active_random_questions(@course, params, session.id)
                                    else
                                      published_active_ordered_questions(@course, params)
                                    end
    render json: { data: questions.map do |question|
      question.serialized_question
    end
    }.merge(paginated_metadata)
  end

  def update_test_session
    session = Session.find(params[:id])

    if check_session_for_valid_update(session)
      # Update session
      session.update_attributes!(update_test_session_params)
    else
      raise_ended_test_error(session.course)
    end

    render json: {}, status: :ok
  end

  # Returns nil if the session is active indicating it can be resumed
  # Or creates/returns a result if the session is over.
  def verify_active_test_session
    session_id = params[:id]

    if session_id.nil?
      raise Errors::BaseError.new(message: "No session ID provided", status: 400)
    end

    # Confirm the presence of the session
    # Using find_by to prevent throwing an error
    session = Session.find_by(id: session_id)

    if session.nil?
      # Check for the result if there's no session
      result = current_user.results.find_by(
        session_key: idempotent_session_key(current_user.id, session_id)
      )

      # Ideally, the result should not be nil if this endpoint is called when resuming a test
      if result.nil?
        # Both Session and Result are non-existent, throw an error
        raise Errors::NotFoundError.new(message: "Cannot find session or result. Please refresh this page")
      else
        # Result available, render that for the user to see
        render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
      end

      return
    end

    if session.user != current_user
      raise Errors::ForbiddenError.new(message: "This is not your session to resume!")
    end

    if check_session_for_valid_update(session)
      # Session still valid, `/start` will be called to resume it
      render json: { data: nil }, status: :ok
    else
      # Session is stale, convert it to a result
      result = get_end_test_result(current_user, session.course)
      render json: result, root: :data, serializer: SessionResultSerializer, status: :created
    end
  end

  def halt_attempts
    message = halt_new_attempts(@course)

    render json: @course, meta: { message: message }, root: :data, serializer: CreatorCourseSerializer
  end

  def close_test
    # Todo: Review this in pt. 2 of the collaborator change
    if !is_course_creator?(@course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have the authority to close this test")
    end

    # Confirm that the lag time is exceeded and the test is closeable
    expiration = @course.test_expiration
    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    closing_time = expiration + (@course.instructions['time']).seconds + lag_time
    is_closeable = closing_time < Time.now

    time_left = distance_of_time_in_words(closing_time, Time.now)
    if !is_closeable
      raise Errors::BaseError.new(message: "Please wait #{time_left} before you can close this test", status: 400)
    end

    # Submit all remaining sessions
    # Alternative?: CourseSessionSubmissionJob.perform_later(course)
    @course.sessions.each do |session|
      begin
        get_end_test_result(session.user, session.course)
      rescue Errors::BaseError
        # Ignored
      end
    end

    # Close the test
    @course.course_status_closed!

    # Send an email to all test-takers
    TestResultsEmailSendJob.perform_later(@course)

    render json: @course, meta: { message: "Test is now Closed!" }, root: :data, serializer: CreatorCourseSerializer
  end

  def test_submissions
    course = Course.find(params[:course_id])
    if !course.test
      raise Errors::ForbiddenError.new(message: "The Course must be a Test!")
    end

    if !is_course_creator?(course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have authority to view these test submissions")
    end

    submissions = course.results.order(created_at: :desc)
    paginated_submissions = paginate(submissions, params)

    render json: paginated_submissions,
           root: :data,
           meta: paginated_meta(paginated_submissions),
           each_serializer: ProfileResultSerializer,
           status: :ok
  end

  def leaderboard
    course = Course.find(params[:course_id])
    if !course.test
      raise Errors::ForbiddenError.new(message: "The Course must be a Test to have a Leaderboard!")
    end

    lag_time = ENV['TEST_LAG_TIME_SECONDS'].to_i.seconds
    user_count = course.results.distinct.count(:user_id)
    closing_time = course.test_expiration + (course.instructions['time']).seconds + lag_time

    # Get first result for the user that isn't disqualified (if any) or the first result (if all are disqualified)
    results = course.results.where(user: current_user)&.order(score: :desc, elapsed_time: :asc, created_at: :asc)
    result = results&.to_a&.find { |r| !r.disqualified } || results&.first

    score = result&.score
    disqualified = result&.disqualified || false

    # Return empty rankings to unauthorised users who want to view the leaderboard before the test is closed
    if !course.course_status_closed? && !is_course_owner?(course, current_user)
      _, _, paginated_metadata = custom_paginate(0, params)
      render json:
               {
                 data: {
                   has_result: !score.nil?,
                   position: nil,
                   score: score,
                   total: result&.total,
                   extra_id: result&.extra_id,
                   disqualified: disqualified,
                   users: user_count,
                   closing_time: closing_time,
                   rankings: []
                 }
               }.merge(paginated_metadata),
             status: :ok
      return
    end

    position = get_ranked_position(course, current_user)

    top_submissions = course.results.order(score: :desc, elapsed_time: :asc, created_at: :asc)
    paginated_submissions = paginate(top_submissions, params)

    render json:
             {
               data: {
                 has_result: !score.nil?,
                 position: disqualified ? nil : position,
                 score: score,
                 total: result&.total,
                 extra_id: result&.extra_id,
                 disqualified: disqualified,
                 users: user_count,
                 closing_time: closing_time,
                 rankings: paginated_submissions.map do |ranked_result|
                   ranked_result.serialized_profile_result
                 end
               },
             }.merge(paginated_meta(paginated_submissions)),
           status: :ok
  end

  def invite_users
    course = Course.session_accessible_courses.find(params[:course_id])

    # Ensure the course is a test
    unless course.test?
      raise Errors::BaseError.new(message: "You can only invite users to a test", status: 400)
    end

    # Check if user has permission to invite
    if !is_course_owner?(course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have the authority to invite users to this test")
    end

    # Check if course is invite-only
    unless course.invite_only?
      raise Errors::BaseError.new(message: "This #{course_or_test(course)} is not set to invite-only", status: 400)
    end

    emails = invite_user_params[:emails] || []

    # Validate email limit (100 max)
    existing_invitations_count = course.test_invitations.count
    if existing_invitations_count + emails.length > 100
      raise Errors::BaseError.new(message: "Cannot exceed 100 invitations per #{course_or_test(course)}", status: 400)
    end

    successful_invites = []
    failed_invites = []

    emails.each do |email|
      begin
        # Check if invitation already exists
        if course.test_invitations.exists?(email: email)
          failed_invites << { email: email, reason: "Already invited" }
          next
        end

        # Create invitation
        invitation = course.test_invitations.create!(
          email: email,
          invited_by: current_user,
          user: User.find_by(email: email) # Link user if they exist
        )

        successful_invites << invitation
      rescue ActiveRecord::RecordInvalid => e
        failed_invites << { email: email, reason: e.message }
      end
    end

    # TODO: Send invitation emails here
    # InvitationMailer.with(invitations: successful_invites, course: @course).send_invitations.deliver_later

    message = ""
    success_count = successful_invites.length
    failure_count = failed_invites.length

    if success_count > 0
      message += "Sent #{success_count} #{'invitation'.pluralize(success_count)} successfully. "
    end

    if failure_count > 0
      message += "#{failure_count} #{'invitation'.pluralize(failure_count)} failed to send."

      if success_count == 0
        raise Errors::BaseError.new(message: message, status: 400)
      end
    end

    if message.blank?
      message = "No invitations were sent."
    end

    render json: {
      data: {
        successful_invites: successful_invites.map(&:email)
      },
      message: message,
    }
  end

  private

  def create_test_based_session(params)
    session = Session.create(params.merge(start_test_session_params))

    if !session
      raise Errors::BaseError.new(message: "Unable to start or resume test", status: 400)
    end

    return session
  end

  def raise_ended_test_error(course)
    # Calculate and return result in the data of the surfaced error
    result = get_end_test_result(
      current_user,
      course,
    ).serialized_result

    raise Errors::ForbiddenError.new(
      message: "Time up! Submitting session...",
      action: :submit,
      data: result
    )
  end

  def get_ranked_position(course, user)
    # Todo: Update the disqualification logic here too to use a course list of disqualified results
    #  For now, disqualified results are not going to exist
    ranked_results_sql = <<~SQL
      SELECT id, user_id, RANK() OVER (ORDER BY score DESC, elapsed_time ASC, created_at ASC) as rank
      FROM results
      WHERE course_id = ?
    SQL
    # WHERE course_id = ? AND (extra_id IS NOT NULL AND extra_id NOT LIKE '%Disqualified')

    user_rank_sql = <<~SQL
      SELECT rank
      FROM (#{ranked_results_sql}) as ranked_results
      WHERE user_id = ?
      LIMIT 1
    SQL

    user_rank = Result.find_by_sql([user_rank_sql, course.id, user.id]).first&.rank

    return user_rank
  end

  def load_test
    begin
      @course = Course.session_accessible_courses.find(params[:course_id])
    rescue ActiveRecord::RecordNotFound
      error_message = "Course data not found - it may have been ended or removed"
      raise Errors::NotFoundError.new(message: error_message)
    end

    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end
  end

  def load_creators_test
    @course = Course.non_deleted_courses.find(params[:course_id])
    # Todo: Add more fine-grained permissions in the Collaborator part 2
    if !is_course_owner?(@course, current_user)
      raise Errors::ForbiddenError.new(message: "You don't have the authority to change this #{course_or_test(@course)}")
    end
  end

  def start_test_session_params
    params.permit(:extra_id, :device_id, :web_tab_id)
  end

  def end_test_session_params
    params.permit(:session_id, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end

  def update_test_session_params
    params.permit(:current_question_number, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end

  def invite_user_params
    params.permit(:emails => [])
  end
end
