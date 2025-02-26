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

  def start_trivia_session(user, trivia, courses, extra_id = nil)
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
        return @current_session

      else
        # Indicate that the session is over and results should be calculated
        return nil
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

      # Start test session
      # Todo: Multi-course sessions
      new_session = {
        user: current_user,
        trivia: @trivia,
        duration: @rules[:time],
        session_type: :trivia,
        session_items: [],
      }

      return new_session
    end
  end

  def check_session_for_valid_update(session)
    init_helper_fields(session.user, session.trivia_set, session.courses)

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
    # TODO: Support Trivia
    session = user.sessions.find_by(trivia_set: trivia)
    questions = course.questions.order(created_at: :asc)

    if params_session_items.present?
      session_items = params_session_items
    else
      if session
        session_items = session.session_items
      else
        raise Errors::BaseError.new(message: "Unable to obtain session, please check your results", status: 400)
      end
    end

    session_items_with_answers = []

    # Merge session items and correct answers to form an answers marking scheme array
    questions.each_with_index do |question, index|
      user_answer = []
      if session_items[index]
        user_answer = session_items[index]["user_answer"]
      end

      session_items_with_answers << {
        question_id: question.id,
        question_version: question.version,
        multiplier: question.multiplier,
        user_answer: user_answer,
        correct_answer: question.answer
      }
    end

    begin
      score, total = mark(session_items_with_answers)
    rescue
      raise Errors::BaseError.new(message: "Unable to calculate result")
    end

    # Use the obtained session to create a Result
    if session
      duration = session.duration
      elapsed_time = [(Time.now - session.created_at).ceil, duration].min

      # Idempotency check to prevent double submissions
      session_key = idempotent_session_key(user.id, session.id)
      result = Result.find_by(session_key: session_key) ||
        Result.create!(
          course: course,
          user: user,
          score: score,
          total: total,
          duration: duration,
          num_questions: session_items_with_answers.size,
          elapsed_time: elapsed_time,
          session_type: :trivia,
          session_key: session_key,
          extra_id: session.extra_id,
          session_items: session_items_with_answers
        )

      # Delete the session after all is done
      session.destroy

      # Register interest in the course's categories
      register_interest(user, course.categories.pluck(:id))

    elsif params_session_id.present?
      # If for some reason, the session no longer exists or has been destroyed
      # Use the id passed in the params to find the session's result
      session_key = idempotent_session_key(current_user.id, params_session_id)
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
