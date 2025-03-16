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

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # If session_param already has an id, return the existing session, otherwise, create a new one
    session = session_param[:id].present? ? session_param : create_test_based_session(session_param)

    questions, paginated_metadata = published_active_ordered_questions(@course, params)
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

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # Existing session, simply assign it
    session = session_param

    # If session doesn't have an id, then it doesn't exist in the DB yet.
    if session[:id].blank?
      raise Errors::BaseError.new(message: "No existing session for this user. Please refresh or check your results", status: 400)
    end

    questions, paginated_metadata = published_active_ordered_questions(@course, params)
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
    params.permit(:session_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end

  def update_test_session_params
    params.permit(:current_question_number, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end
end
