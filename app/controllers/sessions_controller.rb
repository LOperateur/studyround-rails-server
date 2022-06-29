class SessionsController < ApplicationController
  include SessionHelper
  include TestHelper

  skip_before_action :authorize!, only: [:start]
  before_action :load_course

  wrap_parameters format: []

  def start
    if @course.test?
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test")
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
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a)

    render_session_data(session, paginated_questions, false)
  end

  def test_instructions
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test")
    end

    instructions_response = init_test_instructions(current_user, @course)

    render json: {
      data: instructions_response
    }
  end

  def start_test
    if !@course.test?
      raise Errors::BaseError.new(message: "Invalid course type - must be a test")
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
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test")
    end

    type = end_course_session_params[:session_type]
    if type.nil? || type.to_sym == :study || type.to_sym == :test
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    answers = end_course_session_params[:answers]
    num_questions = end_course_session_params[:questions]

    score = 0
    total = 0

    begin
      answers.each do |answer|
        is_german_obj = answer[:correct_answer][0].instance_of? String
        total += answer[:multiplier]

        if is_german_obj
          if !answer[:user_answer].empty? && answer[:correct_answer].map(&:downcase).include?(answer[:user_answer][0].downcase)
            score += answer[:multiplier]
          end
        else
          if answer[:user_answer].sort == answer[:correct_answer].sort
            score += answer[:multiplier]
          end
        end
      end

      # User's session items didn't get to paginate through the total number of questions
      if answers.length < num_questions
        # Assume the remaining questions were 1-point questions and add that to the total
        total += num_questions - answers.length
      end

    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    if end_course_session_params[:session_id].nil?
      raise Errors::BaseError.new(message: "Unknown session!")
    end

    # Idempotency check to prevent double submissions
    session_key = idempotent_session_key(current_user.id, end_course_session_params[:session_id], type)
    result = Result.find_by(session_key: session_key) ||
      Result.create!(
        course: @course, user: current_user, score: score,
        total: total, duration: end_course_session_params[:duration],
        num_questions: num_questions,
        elapsed_time: end_course_session_params[:elapsed_time],
        session_type: end_course_session_params[:session_type],
        session_key: session_key,
        session_items: answers
      )

    render json: result, root: :data, serializer: SessionResultSerializer, status: :ok
  end

  def end_test

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
      raise Errors::BaseError.new(message: "Unable to start or resume test")
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
end
