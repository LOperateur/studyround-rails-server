class QuestionsController < ApplicationController
  include SessionHelper

  skip_before_action :authorize!, only: [:index]
  before_action :load_course

  wrap_parameters format: []

  def index
    case session_type(params[:session_type])
    when :study
      questions = @course.questions.publish_status_published.order(order: :asc)
    when :quiz
      num_questions = params[:questions].to_i
      Course.connection.execute("SELECT SETSEED(#{seed})")
      questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).where.not(options: nil).where("JSONB_ARRAY_LENGTH(answer) = 1").limit(num_questions)
    when :practice
      num_questions = params[:questions].to_i
      Course.connection.execute("SELECT SETSEED(#{seed})")
      questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(num_questions)
    else
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a, params)
    render json: paginated_questions, root: :data, meta: paginated_meta(paginated_questions)
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
