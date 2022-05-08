class SessionsController < ApplicationController
  include SessionHelper

  skip_before_action :authorize!, only: [:start]
  before_action :load_course

  wrap_parameters format: []

  def start
    session = course_based_session

    case session_type(params[:session_type])
    when :study
      questions = @course.questions.publish_status_published
    when :quiz, :practice
      # TODO: Query quiz differently for only single answer OBJ and return error if numbers are less
      num_questions = params[:questions]
      session_id = session[:id]
      Course.connection.execute("SELECT SETSEED(#{session_id_to_seed(session_id)})")
      questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).limit(num_questions)
    else
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    paginated_questions = paginate(questions, { page: 1 })
    render json: {
      data: {
        session: session,
        questions: {
          data: paginated_questions.map do |question|
            question.serialized_question[:question]
          end
        }.merge(paginated_meta(paginated_questions))
      }
    }
  end

  def start_test

  end

  private

  def course_based_session
    {
      id: SecureRandom.random_number.to_s[2..-1].to_i,
      current_question_number: 1,
      server_time: Time.now,
      course_id: @course.id,
      course_name: @course.title,
      session_items: [],
    }
  end

  def load_course
    @course = Course.find(params[:course_id])
  end

  def start_course_session_params
    params.permit(:session_type, :tags, :questions, :duration, :device_id, :web_tab_id)
  end

  def start_test_session_params
    params.permit(:extra_id, :device_id, :web_tab_id)
  end

end
