class SessionsController < ApplicationController
  include SessionHelper
  include TestHelper

  skip_before_action :authorize!, only: [:start]
  before_action :load_course, except: [:update, :verify_active_session]

  wrap_parameters format: []

  # Courses

  def start
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    session_type = session_type(start_course_session_params[:session_type])

    case session_type
    when :study
      session = course_based_session(@course)
      questions = @course.questions.published_active_questions.order(order: :asc)
    when :quiz, :practice
      session, questions = create_course_based_session(start_course_session_params, @course)
    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a)

    render_session_data(session, paginated_questions, false)
  end

  def end
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    type = end_course_session_params[:session_type]
    if type.nil? || type.to_sym == :study || type.to_sym == :test
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end

    session_items_with_answers = end_course_session_params[:answers]
    num_questions = end_course_session_params[:questions]

    begin
      score, total = mark(session_items_with_answers)

      # User's session items didn't get to paginate through the total number of questions
      if session_items_with_answers.length < num_questions
        # Assume the remaining questions were 1-point questions and add that to the total
        total += num_questions - session_items_with_answers.length
      end

    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    if end_course_session_params[:session_id].nil?
      raise Errors::BaseError.new(message: "Unknown session!", status: 400)
    end

    # Idempotency check to prevent double submissions
    session_key = idempotent_session_key(current_user.id, end_course_session_params[:session_id], type)
    result = Result.find_by(session_key: session_key) ||
      Result.create!(
        course: @course,
        user: current_user,
        score: score,
        total: total,
        duration: end_course_session_params[:duration],
        num_questions: num_questions,
        elapsed_time: end_course_session_params[:elapsed_time],
        session_type: end_course_session_params[:session_type],
        session_key: session_key,
        session_items: session_items_with_answers
      )

    # Get and destroy the session
    session = Session.find_by(id: end_course_session_params[:session_id])
    if session
      session.destroy
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  # Tests

  def test_instructions
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end

    instructions_response = init_test_instructions(current_user, @course)

    render json: {
      data: instructions_response
    }
  end

  def start_test
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end

    session_param = get_start_test_session(current_user, @course, start_test_session_params[:extra_id])

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # If session_param already has an id, return the existing session, otherwise, create a new one
    session = session_param[:id].present? ? session_param : create_test_based_session(session_param)

    questions = @course.questions.publish_status_published.order(order: :asc)

    paginated_questions = paginate(questions)

    render_session_data(session.serialized_session[:session], paginated_questions, true)
  end

  def end_test
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end

    result = get_end_test_result(
      current_user,
      @course,
      end_test_session_params[:session_items],
      end_test_session_params[:session_id]
    )

    render json: result, root: :data, serializer: SessionResultSerializer, status: :created
  end

  def update
    session = Session.find(params[:id])

    if check_session_for_valid_update(session)
      # Update session
      session.update_attributes!(update_session_params)
    else
      raise_ended_test_error(session.course)
    end

    render json: {}, status: :ok
  end

  # Returns nil if the session is active indicating it can be resumed
  # Or creates/returns a result if the session is over.
  def verify_active_session
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
        session_key: idempotent_session_key(current_user.id, session_id, :test)
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
      data: result[:result]
    )
  end

  def load_course
    @course = Course.published_active_courses.find(params[:course_id])
  end

  def start_course_session_params
    params.permit(:session_type, :questions, :device_id, :web_tab_id, :duration,
                  :tags => [])
  end

  def end_course_session_params
    params.permit(:session_type, :elapsed_time, :duration, :session_id, :course_id, :questions,
                  :tags => [],
                  :answers => [:question_id, :question_version, :multiplier, :user_answer => [], :correct_answer => []])
  end

  def start_test_session_params
    params.permit(:extra_id, :device_id, :web_tab_id)
  end

  def end_test_session_params
    params.permit(:session_id, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end

  def update_session_params
    params.permit(:current_question_number, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end
end
