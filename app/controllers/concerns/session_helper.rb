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
    year = session_params[:year].presence
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
      # This gives an array of the first 20 questions of which a random 10 are selected just for guest demo purposes
      questions = course.questions.published_active_questions.limit(20).shuffle.first(num_questions)
    else
      if session.session_type_quiz?
        questions = course.questions.published_active_questions.filtered_by_year(year).order(Arel.sql("RANDOM()")).where.not({ options: nil, multi_answer: true }).limit(num_questions)
      else
        questions = course.questions.published_active_questions.filtered_by_year(year).order(Arel.sql("RANDOM()")).limit(num_questions)
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
      # Default to false
      answer[:correct] = false

      is_german_obj = answer[:correct_answer][0].instance_of? String
      total += answer[:multiplier]

      if is_german_obj
        if !answer[:user_answer].empty? && answer[:correct_answer].map {|ans| ans.downcase.strip}.include?(answer[:user_answer][0].downcase.strip)
          answer[:correct] = true
          score += answer[:multiplier]
        end
      else
        if answer[:user_answer].sort == answer[:correct_answer].sort
          answer[:correct] = true
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

  # Fetches ALL the paginated questions for a session in an ordered
  # manner using the linked list approach.
  def published_active_ordered_questions(course, params)
    # Custom pagination for find_by_sql
    total_questions = course.questions.published_active_questions.count
    limit, offset, paginated_metadata = custom_paginate(total_questions, params)

    # Optional year filter
    year = params[:year].presence

    # Recursive CTE to get questions in order
    cte_query = <<-SQL
    WITH RECURSIVE ordered_questions AS (
      SELECT * FROM questions
      WHERE course_id = ?
      AND previous_id IS NULL

      UNION ALL

      SELECT q.* FROM questions q
      INNER JOIN ordered_questions oq ON q.previous_id = oq.id
    )
    SELECT * FROM ordered_questions
    WHERE publish_status = 2
    AND question_status = 1
    AND (? IS NULL OR year = ?) -- Filter by year
    LIMIT ? OFFSET ?
    SQL

    questions = Question.find_by_sql([cte_query, course.id, year, year, limit, offset])

    return questions, paginated_metadata
  end

  def render_session_data(session, paginated_questions, is_test, paginated_metadata = paginated_meta(paginated_questions))
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
        }.merge(paginated_metadata)
      }
    }
  end

  # Populate the session items from the post body with the current question in full
  # This is to keep a reference to the content the user took at the time.
  def flesh_out_session_items(session_items)
    # Fetch all the questions in one query
    question_ids = session_items.map { |session_item| session_item["question_id"] }
    questions = Question.where(id: question_ids)

    full_session_items = []

    session_items.map do |session_item|
      # Get the question from the array of questions
      question = questions.find { |fetched_question| fetched_question.id == session_item["question_id"] }
      #If the question is not found, just skip it
      next if question.nil?
      # Merge the question data into the session item
      session_item.merge!(question.serialized_question_with_answer)
      # Todo: Consider adding the explanation data (would be hidden when rendering session items)
      # session_item[:explanation] = { explanation: question.explanation, explanation_image_asset: question.explanation_image_asset }
      # Then add the full session item to the array
      full_session_items << session_item
    end

    full_session_items
  end

end
