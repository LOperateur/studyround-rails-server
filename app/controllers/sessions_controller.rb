class SessionsController < ApplicationController
  skip_before_action :authorize!, only: [:start]
  before_action :load_course

  wrap_parameters format: []

  def start
    num_questions = params[:questions]
    session = course_based_session

    case params[:session_type].to_sym
    when :study
      questions = @course.questions
    else
      session_id = session[:id]
      Course.connection.execute("SELECT SETSEED(#{session_id_to_seed(session_id)})")
      questions = @course.questions.order(Arel.sql("RANDOM()")).limit(num_questions)
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

  def session_id_to_seed(id)
    # If the id is nil or it doesn't contains only numbers
    if id.nil? || !id.to_s.scan(/\D/).empty?
      SecureRandom.random_number
    else
      ("0." + id.to_s).to_f
    end
  end

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
