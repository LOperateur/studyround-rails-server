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
    when :quiz
      # TODO: Return error if numbers are less
      num_questions = params[:questions]
      session_id = session[:id]
      Course.connection.execute("SELECT SETSEED(#{session_id_to_seed(session_id)})")
      questions = @course.questions.publish_status_published.order(Arel.sql("RANDOM()")).where.not(options: nil).where("JSONB_ARRAY_LENGTH(answer) = 1").limit(num_questions)
    when :practice
      # TODO: Return error if numbers are less
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

  def end
    type = end_course_session_params[:session_type]
    if type.nil? || type.to_sym == :study || type.to_sym == :test
      raise Errors::BaseError.new(message: "Invalid session type")
    end

    answers = end_course_session_params[:answers]

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
    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    result = Result.create!(course: @course, user: current_user, score: score,
                        total: total, duration: params[:duration],
                        elapsed_time: params[:elapsed_time],
                        session_type: "session_type_#{params[:session_type]}".to_sym,
                        session_items: answers)

    render json: result, root: :data, status: :created
  end

  def end_test

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

  def end_course_session_params
    params.permit(:session_type, :elapsed_time, :duration,
                  :answers => [:question_id, :question_version, :multiplier, :user_answer => [], :correct_answer => []])
  end
end
