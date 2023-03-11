module SessionHelper
  extend ActiveSupport::Concern
  # Creates a lightweight session for Quiz and Practice modes
  # It never stores answers nor is it used to mark
  # It's sole purpose is to keep reference to the questions started with as
  # well as some other basic session data
  def create_course_based_session(session_params, course, user_id)
    num_questions = session_params[:questions]
    duration = session_params[:duration]
    session_type = require_session_type(session_params[:session_type])
    check_course_session_limits(num_questions)

    light_course_session = {
      user_id: user_id,
      course: course,
      duration: duration,
      session_type: session_type,
      session_items: [],
    }

    session = Session.new(light_course_session)

    if user_id.nil?
      # Demo session
      # This gives an array of 20 questions of which the first 10 are selected just for guest demo purposes
      questions = course.questions.published_active_questions.limit(20).shuffle.first(num_questions)
    else
      if session.session_type_quiz?
        questions = course.questions.published_active_questions.order(Arel.sql("RANDOM()")).where.not({ options: nil, multi_answer: true }).limit(num_questions)
      else
        questions = course.questions.published_active_questions.order(Arel.sql("RANDOM()")).limit(num_questions)
      end
    end

    check_min_available_questions(questions.length)

    questions.each do |question|
      session.session_items << {
        question_id: question.id
      }
    end

    session.save!

    return course_based_session(course, session_type, session.id, duration), questions
  end

  def course_based_session(course, session_type, session_id = nil, duration = 0)
    {
      # Remove the 0.xxxx decimal prefix
      id: session_id || SecureRandom.random_number.to_s.delete_prefix("0.").to_i,
      current_question_number: 1,
      server_time: DateTime.now.utc,
      start_time: DateTime.now.utc,
      duration: duration,
      session_type: session_type,
      course_id: course.id,
      course_name: course.title,
      session_items: [],
    }
  end

  # Use a session_type string to get the permitted symbolized
  # session type based on the `course_session_types` array
  def require_session_type(session_type)
    if session_type.nil? || !course_session_types.include?(session_type.to_sym)
      raise Errors::BaseError.new(message: "Invalid session type", status: 400)
    end
    session_type.to_sym
  end

  def course_session_types
    [:quiz, :practice, :study]
  end

  def check_course_session_limits(num_questions)
    if num_questions < 10
      raise Errors::BaseError.new(message: "Number of questions should be at least 10", status: 400)
    end
    if num_questions > 50
      raise Errors::BaseError.new(message: "Number of questions should not exceed 50", status: 400)
    end
  end

  def check_min_available_questions(num_questions)
    if num_questions < 10
      raise Errors::BaseError.new(message: "There aren't enough questions to take this course. Please try another course", status: 400)
    end
  end

  def mark(session_items_with_answers)
    score = 0
    total = 0

    session_items_with_answers.each do |answer|
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

    return score, total
  end

  # Returns a uuid that comes from a random seed generated from a deterministic
  # pseudorandom transformation of the user id, session id and session type.
  def idempotent_session_key(user_id, session_id, session_type)
    input = "#{user_id}:#{session_id}:#{session_type.to_s}"
    hash = Digest::MurmurHash64A.rawdigest(input) # Returns an integer
    rnd = Random.new(hash) # Use that integer to seed a new random uuid
    rnd.uuid
  end

  def render_session_data(session, paginated_questions, is_test)
    render json: {
      data: {
        session: session,
        questions: {
          data: paginated_questions.map do |question|
            if is_test
              question.serialized_question[:question]
            else
              question.serialized_question_with_answer[:question]
            end
          end
        }.merge(paginated_meta(paginated_questions))
      }
    }
  end
end
