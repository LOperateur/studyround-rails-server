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
    if session_type.nil? || !session_types.include?(session_type.to_sym)
      raise Errors::BaseError.new(message: "Invalid session type")
    end
    session_type.to_sym
  end

  def session_types
    [:quiz, :practice, :study]
  end

  def check_course_session_limits(num_questions)
    if num_questions < 10
      raise Errors::BaseError.new(message: "Number of questions should be at least 10")
    end
    if num_questions > 50
      raise Errors::BaseError.new(message: "Number of questions should not exceed 50")
    end
  end
end
