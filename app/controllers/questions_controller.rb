class QuestionsController < ApplicationController
  include SessionHelper

  skip_before_action :authorize!, only: [:index]
  before_action :load_course

  wrap_parameters format: []

  def index
    case session_type(params[:session_type])
    when :study
      questions = @course.questions.publish_status_published
    when :quiz, :practice
      max_num_questions = 50
      Course.connection.execute("SELECT SETSEED(#{seed})")
      questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(max_num_questions)
    else
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    paginated_questions = paginate(questions, params)
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
