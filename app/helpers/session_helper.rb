module SessionHelper
  def session_id_to_seed(id)
    # If the id is nil or it doesn't contains only numbers
    if id.nil? || !id.to_s.scan(/\D/).empty?
      SecureRandom.random_number
    else
      ("0." + id.to_s).to_f
    end
  end

  def session_type(session_type)
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

  def convert_session_to_result

  end
end
