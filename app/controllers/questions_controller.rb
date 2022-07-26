class QuestionsController < ApplicationController
  include SessionHelper
  include TestHelper

  before_action :load_course, only: [:index]

  wrap_parameters format: []

  def index
    if @course.test?
      handle_test_index
    else
      handle_course_index
    end
  end

  def explanation
    question = Question.find(params[:question_id])
    render json: {
      data: {
        question_id: question.id,
        explanation: question.explanation,
        explanation_image_url: question.explanation_image_url,
      }
    }
  end

  private

  def load_course
    @course = Course.find(params[:course_id])
  end

  def seed
    session_id = params[:session_id]
    session_id_to_seed(session_id)
  end

  def handle_course_index
    session_type = session_type(params[:session_type])

    case session_type
    when :study
      questions = @course.questions.publish_status_published.order(order: :asc)
    when :quiz, :practice
      num_questions = params[:questions].to_i
      Course.connection.execute("SELECT SETSEED(#{seed})")
      if session_type == :quiz
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).where.not({ options: nil, multi_answer: true }).limit(num_questions)
      else
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(num_questions)
      end
    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a, params)
    render json: paginated_questions, root: :data, each_serializer: QuestionAnswerSerializer, meta: paginated_meta(paginated_questions)
  end

  def handle_test_index
    session_param = get_start_test_session(current_user, @course)

    if session_param.nil?
      raise_ended_test_error(@course)
    end

    # Existing session, simply assign it
    session = session_param

    # If session doesn't have an id, then it doesn't exist in the DB yet.
    if !session[:id].present?
      raise Errors::BaseError.new(message: "No existing session for this user. Please refresh or check your results", status: 400)
    end

    questions = @course.questions.publish_status_published.order(order: :asc)

    paginated_questions = paginate(questions, params)
    render json: paginated_questions, root: :data, meta: paginated_meta(paginated_questions)
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
end
