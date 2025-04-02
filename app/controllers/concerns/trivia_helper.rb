module TriviaHelper
  extend ActiveSupport::Concern

  include SessionHelper
  include UserInterest

  def init_trivia_session_instructions(user, trivia, courses, tz_offset = nil)
    init_helper_fields(user, trivia, courses, tz_offset)

    instructions_array = [
      rules_to_instructions_map[:private], # Provided by the Trivia Info
      rules_to_instructions_map[:expiration], # Provided by the Trivia Info
    ]

    @rules.each do |k, _|
      # Provided instructions for each rule
      instructions_array.append rules_to_instructions_map[k]
    end

    # Rules structure sample
    # {
    #   "time": 600,                         in seconds
    #   "graded": true,
    #   "max_trials": 2,
    #   "user_limit": 0,
    #   "retry_delay": 0,                    in seconds, 0 means no delay
    #   "questions_per_course": 10,
    #   "extra_id_title": "Mat. Number",
    #   "reveal_answers": true
    # }

    {
      trivia: @trivia,
      courses: @courses.map(&:serialized_mini_course),
      resuming: is_user_resuming,
      session_id: if is_user_resuming then @current_session.id else nil end,
      server_time: Time.now.utc, # Send server time to API in UTC T..Z format
      time_left: get_time_left(@rules[:time]),
      start_time: if is_user_resuming then @current_session.created_at else nil end,
      expiration: @trivia.expiration,
      duration: @rules[:time],
      attempts_left: get_max_trials_left(@rules[:max_trials]),
      retry_delay_left: get_retry_delay_left(@rules[:retry_delay]),
      extra_id_title: @rules[:extra_id_title],
      rules: is_closed ? ["This Trivia has been ended"] : instructions_array.compact
    }
  end

  def start_or_resume_trivia_session(user, trivia, courses, extra_id = nil)
    init_helper_fields(user, trivia, courses)

    # Check privacy and invitation key
    if @trivia.private && !has_valid_invitation
      raise Errors::ForbiddenError.new(message: "Invalid invitation key")
    end

    # Check if it has been closed by the creator
    if is_closed
      raise Errors::ForbiddenError.new(message: "This Trivia has been ended")
    end

    # Check if the user is resuming
    if is_user_resuming

      # If there's still time to submit (usually less than the lag time), let them resume
      if get_time_left(@rules[:time]) > 0
        # Resume session
        question_ids = @current_session.session_items.map { |session_item| session_item["question_id"] }
        return @current_session, Question.non_deleted_questions.where(id: question_ids)

      else
        # Indicate that the session is over and results should be calculated
        raise_ended_trivia_session_error(user, trivia)
      end

    else
      # User is starting a fresh new session

      if is_expired(@trivia.expiration)
        raise Errors::ForbiddenError.new(message: "This Trivia is expired")
      end

      if !has_trials_left(@rules[:max_trials])
        raise Errors::ForbiddenError.new(message: "You have exhausted your available trials to partake in this Trivia")
      end

      if !is_retry_cooldown_passed(@rules[:retry_delay])
        raise Errors::ForbiddenError.new(message: "You have to wait for #{get_retry_delay_left(@rules[:retry_delay])} seconds before you can take another session")
      end

      if !has_available_test_slots(@rules[:user_limit])
        raise Errors::ForbiddenError.new(message: "This Trivia is no longer accepting new candidates")
      end

      # Confirm the user enters the required ID if requested
      if !@rules[:extra_id_title].nil? && extra_id.nil?
        raise Errors::BaseError.new(message: "Your #{@rules[:extra_id_title]} is required", status: 400)
      end

      # Create trivia session
      basic_trivia_session = {
        user: user,
        trivia: @trivia,
        duration: @rules[:time],
        session_type: :trivia,
        session_items: [],
      }

      session = Session.new(basic_trivia_session)

      questions = []
      num_questions = @rules[:questions_per_course]

      courses.each do |course|
        course_questions = course.questions.published_active_questions.order(Arel.sql("RANDOM()")).limit(num_questions)

        check_min_available_questions(course_questions.length, course.title)

        # Add all course_questions to the questions array
        questions += course_questions
      end

      questions.each do |question|
        session.session_items << {
          question_id: question.id
        }
      end

      begin
        Session.transaction do
          session.save!
          session.set_multi_courses_with_order(courses)
        end
      rescue
        raise Errors::BaseError.new(message: "Error creating session", status: 400)
      end

      return get_course_based_session(courses, :trivia, session.id, duration), questions
    end
  end

  def check_session_for_valid_update(session)
    init_helper_fields(session.user, session.trivia_set, session.multi_courses)

    # Check if it has been closed by the creator
    if is_closed
      raise Errors::ForbiddenError.new(message: "This Trivia has been ended")
    end

    # If there's still time to submit (usually less than the lag time)
    # `true` - Do nothing, just indicate that it can still be updated
    # `false` - Indicates that the session is over and results should be calculated
    return get_time_left(session.duration) > 0
  end

  def get_end_trivia_result(user, trivia, params_session_items = nil, params_session_id = nil)
    session = user.sessions.find_by(trivia_set: trivia)

    if params_session_items.present?
      session_items = params_session_items
    else
      if session
        session_items = session.session_items
      else
        raise Errors::BaseError.new(message: "Unable to obtain session, please check your results", status: 400)
      end
    end

    session_items_with_answers = flesh_out_session_items(session_items)
    num_questions = session.session_items.length

    begin
      score, total = mark(session_items_with_answers)

      # User's session items didn't get to paginate through the total number of questions
      if session_items_with_answers.length < num_questions
        # Recalculate the total possible score
        total = 0
        session_items_with_answers.each do |item|
          total += item["multiplier"]
        end
      end
    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    # Use the obtained session to create a Result
    if session
      duration = session.duration
      elapsed_time = [(Time.now - session.created_at).ceil, duration].min

      # Idempotency check to prevent double submissions
      session_key = idempotent_session_key(user.id, session.id)
      result = Result.find_by(session_key: session_key)

      # Get the courses from the session
      courses = session.multi_courses

      if result.nil?
        # Create the result if it doesn't already exist
        Result.transaction do
          result = Result.create!(
            trivia_set: trivia,
            user: user,
            score: score,
            total: total,
            duration: duration,
            num_questions: num_questions,
            elapsed_time: elapsed_time,
            session_type: :trivia,
            session_key: session_key,
            extra_id: session.extra_id,
            session_items: session_items_with_answers
          )

          result.set_multi_courses_with_order(courses)
        end
      end

      # Delete the session after all is done
      session.destroy

      courses.each do |course|
        # Register interest in the course's categories
        register_interest(user, course.categories.pluck(:id))
      end

    elsif params_session_id.present?
      # If for some reason, the session no longer exists or has been destroyed
      # Use the id passed in the params to find the session's result
      session_key = idempotent_session_key(user.id, params_session_id)
      begin
        result = Result.find_by!(session_key: session_key)
      rescue
        raise Errors::BaseError.new(message: "Unable to obtain session", status: 404)
      end

    else
      raise Errors::BaseError.new(message: "Unknown session", status: 400)
    end

    return result
  end

  def raise_ended_trivia_session_error(user, trivia)
    # Calculate and return result in the data of the surfaced error
    result = get_end_trivia_result(
      user,
      trivia,
    ).serialized_result

    raise Errors::ForbiddenError.new(
      message: "Time up! Submitting session...",
      action: :submit,
      data: result
    )
  end

  private

  def init_helper_fields(user, trivia, courses, tz_offset = nil)
    @user = user
    @trivia = trivia
    @courses = courses
    @rules = trivia.rules.symbolize_keys
    @current_session = user.sessions.find_by(trivia_set: trivia)
    @tz_offset = tz_offset
  end

  # This maps the rules from the trivia to their respective instructions
  def rules_to_instructions_map
    {
      # Default Trivia Information
      private: privacy_instruction,
      expiration: expiration_instruction,

      # Restrictive rules
      max_trials: map_max_trials_instruction,
      user_limit: map_user_limit_instruction,
      retry_delay: map_retry_delay_instruction,

      # Informative rules
      questions_per_course: num_questions_instruction,
      reveal_answers: map_reveal_answers_instruction,
      extra_id_title: map_extra_id_instruction,
      graded: map_grading_instruction,
    }
  end

  # region Instruction Mapping

  def privacy_instruction
    invited_text = "You have been invited by #{@trivia.creator.username} to take this session"
    uninvited_text = "This session is private, you need a valid invitation to partake"

    if @trivia.private
      has_valid_invitation ? invited_text : uninvited_text
    else
      nil
    end
  end

  def num_questions_instruction
    "There are #{@courses.count * @rules[:questions_per_course]} questions in this session"
  end

  def expiration_instruction
    # Default expiration is 30 days from publishing
    expiration = @trivia.expiration

    if is_expired(expiration)
      total_time = @rules[:time]
      resumption_addendum = ""

      if can_resume(total_time)
        resumption_addendum = ", you are still allowed to resume."
      end

      "This Trivia stopped allowing new attempts on #{expiration.to_formatted_s(:long_ordinal)}#{resumption_addendum} GMT"
    else
      "New attempts for this Trivia will be stopped from #{expiration.to_formatted_s(:long_ordinal)} GMT"
    end
  end

  def map_max_trials_instruction
    max_trials = @rules[:max_trials]

    max_trials_left = get_max_trials_left(max_trials)

    message = "You have #{max_trials_left} #{'chance'.pluralize(max_trials_left)}"
    message += " left" if max_trials_left < max_trials
    message += " to take and submit this Trivia"

    return message
  end

  def map_retry_delay_instruction
    max_trials = @rules[:max_trials]
    retry_delay = @rules[:retry_delay]

    # Return nil if there is no retry delay set.
    return nil if retry_delay.nil?

    max_trials_left = get_max_trials_left(max_trials)
    retry_delay_left = get_retry_delay_left(retry_delay)

    # Return nil if no trials remain after the end of the current session.
    return nil if max_trials_left <= 1

    # Determine which message to display.
    if is_user_resuming || retry_delay_left <= 0
      "When you finish this session, you will have to wait #{retry_delay || 0} seconds before you can retake another"
    else
      "You will have to wait #{retry_delay_left} seconds before you can take this session"
    end
  end

  def map_user_limit_instruction
    user_limit = @rules[:user_limit]

    available_test_slots = get_available_test_slots(user_limit)

    if available_test_slots.nil?
      return nil
    end

    "There #{available_test_slots > 1 ? 'are' : 'is'} #{available_test_slots} more candidate #{'slot'.pluralize(available_test_slots)} left for this Trivia"
  end

  def map_reveal_answers_instruction
    reveal_answers = @rules[:reveal_answers]

    reveal_answers_text = "Upon submission, your answers for each question would be available for review"
    hidden_answers_text = "Upon submission, your answers for each question would NOT be available for review until this Trivia is closed by the creator"

    reveal_answers ? reveal_answers_text : hidden_answers_text
  end

  def map_extra_id_instruction
    extra_id_title = @rules[:extra_id_title]

    if extra_id_title.nil?
      return nil
    end

    "Your '#{extra_id_title}' has been requested before starting the session"
  end

  def map_grading_instruction
    graded = @rules[:graded]

    graded_text = "This session will be graded and you will see your score immediately you submit"
    ungraded_text = "There will be no grading in answers."

    graded ? graded_text : ungraded_text
  end

  # endregion

  # region Validation Getters

  def get_time_left(total_time)
    if is_user_resuming
      # to_time (or Time.now) is more compatible when calculating with DB's ActiveSupport::TimeWithZone
      time_left = @current_session.created_at + (@current_session.duration).seconds - Time.now
    else
      # If session does not exist, use total_time instead
      time_left = total_time
    end

    return time_left.floor
  end

  def get_max_trials_left(max_trials)
    trials_taken = @user.results.where(trivia_set: @trivia).count
    return (max_trials.to_i) - trials_taken
  end

  def get_retry_delay_left(retry_delay)
    return 0 if retry_delay.nil?

    last_result = @user.results.where(trivia_set: @trivia).last
    if last_result.present?
      last_result_time = last_result.created_at
      time_since_last_result = Time.now - last_result_time
      return (retry_delay.to_i) - time_since_last_result
    end
  end

  def get_available_test_slots(user_limit)
    # No need to check for test slots if it's unlimited (zero), user is resuming or user already has a result
    return nil if user_limit == 0 || is_user_resuming || @user.results.exists?(trivia_set: @trivia)

    used_sessions = Session.where(trivia_set: @trivia).distinct.count(:user_id)
    used_results = Result.where(trivia_set: @trivia).distinct.count(:user_id)

    return user_limit - used_sessions - used_results
  end

  # endregion

  # region Validation Checks

  # Check if the user was invited for the private Trivia
  def has_valid_invitation
    # Todo: Validate Invitation properly and pass the key through method parameters
    # return validate(params[:invite_key])
    return true
  end

  def is_user_resuming
    return !@current_session.nil?
  end

  # Check if the Trivia has been closed by the creator
  # The user cannot start or resume a session in a closed Trivia
  def is_closed
    return @trivia.trivia_status_closed?
  end

  # Check if the Trivia has expired
  # The user cannot start a session in an expired Trivia but can resume one
  def is_expired(expiration)
    expired = Time.now > expiration

    # If the time indicates it's expired but the course doesn't
    # have an expired or closed status, then expire the course.
    if expired && !(@trivia.trivia_status_expired? || @trivia.trivia_status_closed?)
      @trivia.trivia_status_expired!

      # Handle email notifications
      # TODO: @course.send_test_status_emails
    end

    return expired
  end

  # Check if the user can resume this session (even if Trivia is expired)
  def can_resume(total_time)
    return is_user_resuming && get_time_left(total_time) > 0
  end

  # Check the amount of times this user has to take this Trivia
  # If a resuming user has 0 trials left, they can still resume
  def has_trials_left(max_trials)
    return get_max_trials_left(max_trials) > 0
  end

  def is_retry_cooldown_passed(retry_delay)
    return get_retry_delay_left(retry_delay) <= 0
  end

  # Check if candidacy has been exceeded
  def has_available_test_slots(user_limit)
    return get_available_test_slots(user_limit).nil? || get_available_test_slots(user_limit) > 0
  end

  # endregion
end
