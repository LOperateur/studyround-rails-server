class QuestionsController < ApplicationController
  include SessionHelper

  skip_before_action :authorize!, only: [:index]
  before_action :load_course, only: [:index]

  wrap_parameters format: []

  def index
    session_type = session_type(params[:session_type])

    case session_type
    when :study
      questions = @course.questions.publish_status_published.order(order: :asc)
    when :quiz, :practice
      num_questions = params[:questions].to_i
      Course.connection.execute("SELECT SETSEED(#{seed})")
      if session_type == :quiz
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).where.not(options: nil).where("JSONB_ARRAY_LENGTH(answer) = 1").limit(num_questions)
      else
        questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(num_questions)
      end
    else
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a, params)
    render json: paginated_questions, root: :data, meta: paginated_meta(paginated_questions)
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
end
