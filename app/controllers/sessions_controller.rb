class SessionsController < ApplicationController
  include SessionHelper
  include TestHelper

  skip_before_action :authorize!, only: [:start]
  before_action :load_course, except: [:update]

  wrap_parameters format: []

  def start
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end

    session = course_based_session
    session_type = session_type(params[:session_type])

    case session_type
    when :study
      questions = @course.questions.publish_status_published.order(order: :asc)
    when :quiz, :practice
      num_questions = params[:questions]
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

    session_param = get_start_test_session(current_user, @course)

    # If session_param already has an id, return the existing session, otherwise, create a new one
    session = session_param[:id].present? ? session_param : create_test_based_session(session_param)

    questions = @course.questions.publish_status_published.order(order: :asc)

    paginated_questions = paginate(questions)

    render_session_data(session.serialized_session[:session], paginated_questions, true)
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

  def end_test
    questions = @course.questions.order(order: :asc)
    session_items = end_test_session_params[:session_items]
    session_items_with_answers = []

    # Merge session items and correct answers to form an answers marking scheme array
    questions.each_with_index do |question, index|
      user_answer = []
      if session_items[index]
        user_answer = session_items[index][:user_answer]
      end

      session_items_with_answers << {
        question_id: question.id,
        question_version: question.version,
        multiplier: question.multiplier,
        user_answer: user_answer,
        correct_answer: question.answer
      }
    end

    begin
      score, total = mark(session_items_with_answers)
    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    # Find the session and use it to create a Result
    session = current_user.sessions.find_by(course: @course)
    if session
      duration = @course.instructions["time"]
      elapsed_time = [(DateTime.now.to_time - session.created_at).ceil, duration].min

      # Idempotency check to prevent double submissions
      session_key = idempotent_session_key(current_user.id, session.id, :test)
      result = Result.find_by(session_key: session_key) ||
        Result.create!(
          course: @course,
          user: current_user,
          score: score,
          total: total,
          duration: duration,
          num_questions: session_items_with_answers.size,
          elapsed_time: elapsed_time,
          session_type: :test,
          session_key: session_key,
          session_items: session_items_with_answers
        )

      # Delete the session after all is done
      session.destroy

    else
      # If for some reason, the session no longer exists or has been destroyed
      # Use the id passed in the params to find the session's result
      session_key = idempotent_session_key(current_user.id, end_test_session_params[:session_id], :test)
      result = Result.find_by!(session_key: session_key)
    end

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def update
    session = Session.find(params[:id])

    if check_session_for_valid_update(session)
      # Update session
      session.update_attributes!(update_session_params)
    end

    render json: {}, status: :ok
  end

  private

  def course_based_session
    {
      # Remove the 0.xxxx decimal prefix
      id: SecureRandom.random_number.to_s[2..-1].to_i,
      current_question_number: 1,
      server_time: DateTime.now.utc,
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

  def load_course
    @course = Course.find(params[:course_id])
  end

  def start_course_session_params
    params.permit(:session_type, :tags, :questions, :duration, :device_id, :web_tab_id)
  end

  def start_test_session_params
    # If using the path param (course_id) for constructing a model, you have to permit it too
    params.permit(:course_id, :extra_id, :device_id, :web_tab_id)
  end

  def end_course_session_params
    params.permit(:session_type, :elapsed_time, :duration, :session_id, :course_id, :questions,
                  :tags => [],
                  :answers => [:question_id, :question_version, :multiplier, :user_answer => [], :correct_answer => []])
  end

  def end_test_session_params
    params.permit(:session_id, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end

  def update_session_params
    # If using the path param (id) for updating a model, you have to permit it too
    params.permit(:id, :current_question_number, :device_id, :web_tab_id,
                  :session_items => [:question_id, :question_version, :multiplier, :user_answer => []])
  end
end
