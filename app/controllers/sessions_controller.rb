class SessionsController < ApplicationController
  include SessionHelper
  include TestHelper
  include UserInterest

  skip_before_action :authorize!, only: [:start_demo, :end_demo]
  before_action :load_course, except: [:update, :verify_active_session]

  wrap_parameters format: []

  # Courses

  def start
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    if @course.sale_status_paid?
      if !current_user.has_purchased_item(@course)
        raise Errors::ForbiddenError.new(message: "Please purchase this course before using it")
      end
    end

    session_type = require_session_type(start_course_session_params[:session_type])

    case session_type
    when :study
      session = course_based_session(@course, :study)
      questions, paginated_metadata = published_active_ordered_questions(@course, params)
      render_session_data(session, questions, false, paginated_metadata)
      return # Return early to avoid the rest of the method
    when :quiz, :practice
      session, questions = create_course_based_session(start_course_session_params, @course, current_user.id)
    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end

    # Converting to array to calculate the offset page data w.r.t `num_questions`
    # This is because we call `limit` on the questions to get the first `num_questions`
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

    # Include the question json data here to save
    session_items_with_answers = flesh_out_session_items(end_course_session_params[:answers])
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

    session = Session.find_by(id: end_course_session_params[:session_id])

    if session
      duration = session.duration
      elapsed_time = [(DateTime.now.to_time - session.created_at).ceil, duration].min

      # Idempotency check to prevent double submissions
      session_key = idempotent_session_key(current_user.id, session.id, type)
      result = Result.find_by(session_key: session_key) ||
        Result.create!(
          course: @course,
          user: current_user,
          score: score,
          total: total,
          duration: duration,
          num_questions: num_questions,
          elapsed_time: elapsed_time,
          session_type: type,
          session_key: session_key,
          session_items: session_items_with_answers
        )

      # Delete the session
      session.destroy

      # Register interest in the course's categories
      register_interest(current_user, @course.categories.pluck(:id))

    else
      # If for some reason, the session no longer exists or has been destroyed
      # Use the id passed in the params to find the session's result
      session_key = idempotent_session_key(current_user.id, end_course_session_params[:session_id], type)
      begin
        result = Result.find_by!(session_key: session_key)
      rescue
        raise Errors::NotFoundError.new(message: "Unable to obtain session")
      end
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def start_demo
    if current_user
      raise Errors::BaseError.new(message: "Logged in users cannot take a demo", status: 400)
    end

    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    if @course.sale_status_paid?
      raise Errors::BaseError.new(message: "Invalid course type - paid tests not available for demo", status: 400)
    end

    # Solely for the purpose of this demo
    start_course_session_params = {
      session_type: :practice,
      duration: 300,
      questions: 10,
    }

    session, questions = create_course_based_session(start_course_session_params, @course, nil)

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a)

    render_session_data(session, paginated_questions, false)
  end

  def end_demo
    if current_user
      raise Errors::BaseError.new(message: "Logged in users cannot take a demo", status: 400)
    end

    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    # Solely for the purpose of this demo
    session_type = :practice
    num_questions = 10

    # Include the question json data here
    session_items_with_answers = flesh_out_session_items(end_course_session_params[:answers])

    begin
      score, total = mark(session_items_with_answers)
    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    guest_id = end_course_session_params[:guest_id]

    if guest_id.nil?
      raise Errors::BaseError.new(message: "Unknown guest user!", status: 400)
    end

    guest_email = end_course_session_params[:guest_email]

    if guest_email.blank?
      raise Errors::BaseError.new(message: "No email provided!", status: 400)
    end

    if end_course_session_params[:session_id].nil?
      raise Errors::BaseError.new(message: "Unknown session!", status: 400)
    end

    session = Session.find_by(id: end_course_session_params[:session_id])

    if session
      duration = session.duration
      elapsed_time = [(DateTime.now.to_time - session.created_at).ceil, duration].min

      # Idempotency check
      session_key = idempotent_session_key(guest_id, session.id, session_type)
      result = Result.new(
        course: @course,
        score: score,
        total: total,
        duration: duration,
        num_questions: num_questions,
        elapsed_time: elapsed_time,
        session_type: session_type,
        session_key: session_key,
        session_items: session_items_with_answers
      )

      # Delete the session
      session.destroy

      # Save the result to the guest
      guest = Guest.find(guest_id)
      guest.update!(result: result.as_json)
    end

    # TODO: Move this to a shared concern
    # Send the invite/results email
    guests_controller = GuestsController.new
    guests_controller.request = request
    guests_controller.response = response

    guest_invite_params = { guest_id: guest_id, email: guest_email }

    guests_controller.params = guest_invite_params

    render json: guests_controller.invite
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
    render_session_data(session.serialized_session[:session], questions, true, paginated_metadata)
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
    @course = Course.session_accessible_courses.find(params[:course_id])
  end

  def start_course_session_params
    params.permit(:session_type, :questions, :device_id, :web_tab_id, :duration, :year,
                  :tags => [])
  end

  def end_course_session_params
    params.permit(:session_type, :session_id, :questions, :guest_id, :guest_email,
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