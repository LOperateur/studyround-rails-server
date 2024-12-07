class SessionsController < ApplicationController
  include SessionHelper
  include UserInterest

  skip_before_action :authorize!, only: [:start_demo, :end_demo]
  before_action :load_courses, only: [:start, :start_demo]

  wrap_parameters format: []

  def start
    @courses.each do |course|
      if course.sale_status_paid? && !current_user.has_purchased_item(course)
        raise Errors::ForbiddenError.new(message: "Please purchase selected course(s) before use")
      end
    end

    session_type = require_session_type(start_course_session_params[:session_type])

    case session_type
    when :study
      session = get_course_based_session(@courses, :study)
      questions, paginated_metadata = published_active_ordered_questions(@courses.first, params)
      render_session_data(session, questions, false, paginated_metadata)

    when :quiz, :practice
      session, questions = create_course_based_session(start_course_session_params, @courses, current_user.id)
      # Converting to array to calculate the offset page data w.r.t `num_questions`
      # This is because we call `limit` on the questions to get the first `num_questions`
      paginated_questions = paginate(questions.to_a)
      render_session_data(session, paginated_questions, false)

    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end
  end

  def end
    session = Session.find_by(id: params[:id])

    if session
      # Include the question json data here to save
      session_items_with_answers = flesh_out_session_items(end_course_session_params[:answers])
      num_questions = session.session_items.length

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

      if params[:id].nil?
        raise Errors::BaseError.new(message: "Unknown session!", status: 400)
      end


      type = session.session_type
      duration = session.duration
      elapsed_time = [(DateTime.now.to_time - session.created_at).ceil, duration].min

      # Idempotency check to prevent double submissions
      session_key = idempotent_session_key(current_user.id, session.id)

      # Check if the result already exists
      result = Result.find_by(session_key: session_key)

      # Get the courses from the session
      courses = session.multi_courses

      if result.nil?
        # Create the result if it doesn't already exist
        Result.transaction do
          result = Result.create!(
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

          result.set_multi_courses_with_order(courses)
        end
      end

      # Delete the session
      session.destroy

      courses.each do |course|
        # Register interest in the course's categories
        register_interest(current_user, course.categories.pluck(:id))
      end

    else
      # If for some reason, the session no longer exists or has been destroyed
      # Use the session key to find the session's result
      session_key = idempotent_session_key(current_user.id, params[:id])
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

    if @courses.any? { |course| course.sale_status_paid? }
      raise Errors::BaseError.new(message: "Invalid course type - paid courses not available for demo", status: 400)
    end

    # Solely for the purpose of this demo
    start_course_session_params = {
      session_type: :practice,
      duration: 300,
      questions: 10,
    }

    session, questions = create_course_based_session(start_course_session_params, @courses, nil)

    # Converting to array to calculate the offset page data w.r.t num_questions
    paginated_questions = paginate(questions.to_a)

    render_session_data(session, paginated_questions, false)
  end

  def end_demo
    if current_user
      raise Errors::BaseError.new(message: "Logged in users cannot take a demo", status: 400)
    end

    # Obtain guest information
    guest_id = end_course_session_params[:guest_id]
    if guest_id.nil?
      raise Errors::BaseError.new(message: "Unknown guest user!", status: 400)
    end

    session = Session.find_by(id: params[:id])

    if session
      # Include the question json data here
      session_items_with_answers = flesh_out_session_items(end_course_session_params[:answers])

      begin
        score, total = mark(session_items_with_answers)
      rescue
        raise Errors::BaseError.new(message: "Unable to calculate result")
      end

      duration = session.duration
      elapsed_time = [(Time.now - session.created_at).ceil, duration].min

      # Idempotency check
      session_key = idempotent_session_key(guest_id, session.id)

      # Get the courses from the session
      courses = session.multi_courses
      course_ids = courses.map(&:id)

      result = Result.new(
        score: score,
        total: total,
        duration: duration,
        num_questions: session.session_items.length,
        elapsed_time: elapsed_time,
        session_type: session.session_type,
        session_key: session_key,
        session_items: session_items_with_answers
      )

      # Delete the session
      session.destroy

      # Save the result to the guest
      guest = Guest.find(guest_id)
      guest.update!(result: result.as_json.merge('multi_course_ids' => course_ids))
    else
      # If for some reason, the session no longer exists or has been destroyed
      # Use the guest details to find the session's result
      begin
        guest = Guest.find(guest_id)
        result = guest.result
        score = result['score'].to_i
        total = result['total'].to_i
      rescue
        raise Errors::NotFoundError.new(message: "Unable to obtain session")
      end
    end

    # Send the invite/results email if the guest provided an email
    guest_email = end_course_session_params[:guest_email]

    if guest_email.present?
      # TODO: Move this to a shared concern
      # Send the invite/results email if the guest provided an email
      guests_controller = GuestsController.new
      guests_controller.request = request
      guests_controller.response = response

      guest_invite_params = { guest_id: guest_id, email: guest_email }

      guests_controller.params = guest_invite_params

      render json: guests_controller.invite
    else
      # If no email was provided, just return the result
      render json: {
        data: {
          result: {
            guest_id: guest_id,
            score: score,
            total: total,
          }
        }
      }, status: :ok
    end
  end

  def questions
    session = Session.find(params[:id])
    session_type = session.session_type.to_sym

    case session_type
    when :study
      questions, paginated_metadata = published_active_ordered_questions(session.multi_courses.first, params)
      render json: { data: questions.map do |question|
        question.serialized_question_with_answer
      end
      }.merge(paginated_metadata)

    when :quiz, :practice
      session = Session.find(params[:id])
      question_ids = session.session_items.map { |session_item| session_item["question_id"] }

      # Sort by the order of ids supplied
      questions = Question.where(id: question_ids).sort_by { |i| question_ids.index(i.id) }

      paginated_questions = paginate(questions, params)
      render json: paginated_questions, root: :data, each_serializer: QuestionAnswerSerializer, meta: paginated_meta(paginated_questions)

    else
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end
  end

  private

  def load_courses
    begin
      @courses = []
      course_ids = params[:courses]

      course_ids.each do |course_id|
        @courses << Course.session_accessible_courses.find(course_id)
      end

    rescue ActiveRecord::RecordNotFound
      error_message = "Some course data was not found - it may have been removed"
      raise Errors::NotFoundError.new(message: error_message)
    end

    if @courses.empty?
      raise Errors::BaseError.new(message: "Please select at least 1 course", status: 400)
    end

    if @courses.any? { |course| course.test? }
      raise Errors::BaseError.new(message: "Invalid course type - cannot be a test", status: 400)
    end
  end

  def start_course_session_params
    params.permit(:session_type, :questions, :device_id, :web_tab_id, :duration, :year,
                  :courses => [], :tags => [])
  end

  def end_course_session_params
    params.permit(:guest_id, :guest_email,
                  :answers => [:question_id, :question_version, :multiplier, :user_answer => [], :correct_answer => []])
  end
end
