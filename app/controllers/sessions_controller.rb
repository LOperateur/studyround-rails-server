class SessionsController < ApplicationController
  include SessionHelper
  include TestHelper

  skip_before_action :authorize!, only: [:start, :submit_stale_sessions]
  before_action :load_course, except: [:update, :submit_stale_sessions]

  wrap_parameters format: []

  # Courses

  def start
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    session = course_based_session
    session_type = session_type(start_course_session_params[:session_type])

    case session_type
    when :study
      questions = @course.questions.publish_status_published.order(order: :asc)
    when :quiz, :practice
      num_questions = start_course_session_params[:questions]
      check_course_session_limits(num_questions)
      session_id = session[:id]
      Course.connection.execute("SELECT SETSEED(#{session_id_to_seed(session_id)})")
      if session_type == :quiz
        # where("JSONB_ARRAY_LENGTH(answer) = 1")
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).where.not({ options: nil, multi_answer: true }).limit(num_questions)
      else
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(num_questions)
      end
      check_min_available_questions(questions.length)
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

  # Verify if a resuming test can resume or should start a new one/render it's last result.
  # IMPORTANT: Should ideally be called only when the user is resuming a test.
  def verify_active_test
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end

    # Confirm the presence of the latest session
    last_session = current_user.sessions.recent.find_by(course: @course)

    if last_session.nil?
      # Check for any result if there's no session
      latest_result = current_user.results.recent.find_by(course: @course)

      # Ideally, latest result should not be nil if this endpoint is called when resuming a test
      if latest_result.nil?
        # Both Session and Result are non-existent, `/start` will be called to start a new one
        render json: { data: nil }, status: :ok
      else
        # Result available, render that for the user to see
        render json: latest_result, root: :data, serializer: SessionResultSerializer, status: :ok
      end

      return
    end

    if check_session_for_valid_update(last_session)
      # Session still valid, `/start` will be called to resume it
      render json: { data: nil }, status: :ok
    else
      # Session is stale, convert it to a result
      result = get_end_test_result(current_user, last_session.course)
      render json: result, root: :data, serializer: SessionResultSerializer, status: :created
    end
  end

  def verify_active_session
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test", status: 400)
    end

    session_id = params[:id]

    if session_id.nil?
      raise Errors::BaseError.new(message: "No session ID provided", status: 400)
    end

    # Confirm the presence of the session
    session = Session.find(session_id)

    if session.nil?
      # Check for the result if there's no session
      result = current_user.results.find_by(
        session_key: idempotent_session_key(user.id, session_id, :test)
      )

      # Ideally, the result should not be nil if this endpoint is called when resuming a test
      if result.nil?
        # Both Session and Result are non-existent, throw an error
        raise Errors::NotFoundError.new(message: "Cannot find result. Please refresh this page")
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

  def submit_stale_sessions
    recent_sessions = Session.where({ session_type: :test }).created_after(36.hours.ago)

    recent_sessions.each do |session|
      begin
        # Sessions that cannot be updated are considered stale
        if check_session_for_valid_update(session).nil?
          get_end_test_result(session.user, session.course)
        end
      rescue Errors::BaseError
        # Ignored
      end
    end
  end

  private

  def course_based_session
    {
      # Remove the 0.xxxx decimal prefix
      id: SecureRandom.random_number.to_s.delete_prefix("0.").to_i,
      current_question_number: 1,
      server_time: DateTime.now.utc,
      start_time: DateTime.now.utc,
      course_id: @course.id,
      course_name: @course.title,
      session_items: [],
    }
  end

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
    @course = Course.find(params[:course_id])
  end

  def start_course_session_params
    params.permit(:session_type, :questions, :device_id, :web_tab_id,
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
