module TestHelper
  extend ActiveSupport::Concern

  include SessionHelper
  include UserInterest

  def init_test_instructions(user, course)
    @user = user
    @course = course
    @instructions = course.instructions.symbolize_keys

    @current_session = user.sessions.find_by(course: course)

    instructions_array = [
      instructions_map[:private],
      instructions_map[:num_questions],
      instructions_map[:expiration],
    ]

    @instructions.each do |k, v|
      instructions_array.append instructions_map[k]
    end

    # This should always be present
    # Todo: If it's not, then it's a bug from the frontend, fix that
    # Check if the "pause_on_quit" instruction is present in the instructions json
    if !@instructions.key?(:pause_on_quit)
      instructions_array.append instructions_map[:pause_on_quit]
    end

    course.serialized_mini_course.merge(
      {
        resuming: is_user_resuming,
        session_id: if is_user_resuming then @current_session.id else nil end,
        server_time: Time.now.utc, # Send server time to API in UTC T..Z format
        time_left: get_time_left(@instructions[:time]),
        start_time: if is_user_resuming then @current_session.created_at else nil end,
        expiration: @course.test_expiration,
        duration: @instructions[:time],
        attempts_left: get_max_trials_left(@instructions[:max_trials]),
        extra_id_title: @instructions[:extra_id_title],
        instructions: is_closed ? ["This test has been ended"] : instructions_array.compact
      }
    )
  end

  def get_start_test_session(user, course, extra_id = nil)
    @user = user
    @course = course
    @instructions = course.instructions.symbolize_keys

    @current_session = user.sessions.find_by(course: course)

    # Check privacy and invitation key
    if @course.private && !has_valid_invitation
      raise Errors::ForbiddenError.new(message: "Invalid invitation key")
    end

    # Check if it has been closed by the creator
    if is_closed
      raise Errors::ForbiddenError.new(message: "This test has been ended")
    end

    # Check if the user is resuming
    if is_user_resuming

      # If there's still time to submit (usually less than the lag time), let them resume
      if get_time_left(@instructions[:time]) > 0
        # Resume test session
        return @current_session

      else
        # Indicate that the session is over and results should be calculated
        return nil
      end

    else
      # User is starting a fresh new session

      if is_expired(course.test_expiration)
        raise Errors::ForbiddenError.new(message: "This test is expired")
      end

      if !has_trials_left(@instructions[:max_trials])
        raise Errors::ForbiddenError.new(message: "You have exhausted your available trials to take this test")
      end

      if !has_available_test_slots(@instructions[:user_limit])
        raise Errors::ForbiddenError.new(message: "This test is no longer accepting new candidates")
      end

      # Confirm the user enters the required ID if requested
      if !@instructions[:extra_id_title].nil? && extra_id.nil?
        raise Errors::BaseError.new(message: "Your #{@instructions[:extra_id_title]} is required", status: 400)
      end

      # Start test session
      new_session = {
        user: current_user,
        course: @course,
        duration: @instructions[:time],
        session_type: :test,
        session_items: [],
      }

      return new_session
    end
  end

  def check_session_for_valid_update(session)
    @course = session.course
    @current_session = session

    # Check if it has been closed by the creator
    if is_closed
      raise Errors::ForbiddenError.new(message: "This test has been ended")
    end

    # If there's still time to submit (usually less than the lag time)
    # `true` - Do nothing, just indicate that it can still be updated
    # `false` - Indicates that the session is over and results should be calculated
    return get_time_left(session.duration) > 0
  end

  def get_end_test_result(user, course, params_session_items = nil, params_session_id = nil)
    session = user.sessions.find_by(course: course)
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
          session_type: :test,
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

  # Allows a creator to immediately mark a test as expired.
  # This is useful for when a creator wants to end a test early.
  # Note: Expiry isn't an indication that the test is closed, users can still
  # submit their sessions if they started the test before the expiry time.
  def halt_new_attempts(course)
    @course = course

    if is_closed
      raise Errors::BaseError.new(message: "This Test is already over! Further action cannot be taken.", status: 400)
    end

    if is_expired(course.test_expiration)
      return "This test is already expired."
    else
      course.test_expiration = Time.now
      course.save!

      # Call this to handle the process of updating the status and sending notifications
      is_expired(course.test_expiration)
      return "Test Expired! New attempts are halted."
    end
  end

  private

  # region Basic private functions

  def instructions_map
    {
      # Default test instructions
      private: privacy_instruction,
      num_questions: num_questions_instruction,

      # Restrictive instructions
      expiration: expiration_instruction,
      max_trials: map_max_trials_instruction,
      user_limit: map_user_limit_instruction,

      # Informative instructions
      reveal_answers: map_reveal_answers_instruction,
      extra_id_title: map_extra_id_instruction,
      graded: map_grading_instruction,
      pause_on_quit: "You can leave this test and resume later but your timer would count down while you're away"
    }
  end

  # endregion

  # region Instruction Mapping

  def privacy_instruction
    invited_text = "You have been invited by #{@course.creator.username} to take this test"
    uninvited_text = "This test is private, you need a valid invitation to partake"

    if @course.private
      has_valid_invitation ? invited_text : uninvited_text
    else
      nil
    end
  end

  def num_questions_instruction
    "There are #{@course.questions.count} questions in this test"
  end

  def expiration_instruction
    # Default expiration is 30 days from publishing
    expiration = @course.test_expiration

    if is_expired(expiration)
      total_time = @instructions[:time]
      resumption_addendum = ""

      if can_resume(total_time)
        resumption_addendum = ", you are still allowed to resume."
      end

      "This test stopped allowing new attempts on #{expiration.to_formatted_s(:long_ordinal)}#{resumption_addendum} GMT"
    else
      "New attempts for this test will be stopped from #{expiration.to_formatted_s(:long_ordinal)} GMT"
    end
  end

  def map_max_trials_instruction
    max_trials = @instructions[:max_trials]

    max_trials_left = get_max_trials_left(max_trials)

    message = "You have #{max_trials_left} #{'chance'.pluralize(max_trials_left)}"
    message += " left" if max_trials_left < max_trials
    message += " to take and submit this test"

    return message
  end

  def map_user_limit_instruction
    user_limit = @instructions[:user_limit]

    available_test_slots = get_available_test_slots(user_limit)

    if available_test_slots.nil?
      return nil
    end

    "There #{available_test_slots > 1 ? 'are' : 'is'} #{available_test_slots} more candidate #{'slot'.pluralize(available_test_slots)} left for this test"
  end

  def map_reveal_answers_instruction
    reveal_answers = @instructions[:reveal_answers]

    reveal_answers_text = "Upon submission, your answers for each question would be available for review"
    hidden_answers_text = "Upon submission, your answers for each question would NOT be available for review until this test is closed by the creator"

    reveal_answers ? reveal_answers_text : hidden_answers_text
  end

  def map_extra_id_instruction
    extra_id_title = @instructions[:extra_id_title]

    if extra_id_title.nil?
      return nil
    end

    "Your '#{extra_id_title}' has been requested before starting the test"
  end

  def map_grading_instruction
    graded = @instructions[:graded]

    graded_text = "This test will be graded and you will see your score immediately you submit"
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
    trials_taken = @user.results.where(course: @course).count
    return (max_trials.to_i) - trials_taken
  end

  def get_available_test_slots(user_limit)
    # No need to check for test slots if it's unlimited (zero), user is resuming or user already has a result
    return nil if user_limit == 0 || is_user_resuming || @user.results.exists?(course: @course)

    used_sessions = Session.where(course: @course).distinct.count(:user_id)
    used_results = Result.where(course: @course).distinct.count(:user_id)

    return user_limit - used_sessions - used_results
  end

  # endregion

  # region Validation Checks

  # Check if the user was invited for the private test
  def has_valid_invitation
    # Todo: Validate Invitation properly and pass the key through method parameters
    # return validate(params[:invite_key])
    return true
  end

  def is_user_resuming
    return !@current_session.nil?
  end

  # Check if the test has been closed by the creator
  # The user cannot start or resume a closed test
  def is_closed
    return @course.course_status_closed?
  end

  # Check if the test has expired
  # The user cannot start an expired but can resume one
  def is_expired(expiration)
    expired = Time.now > expiration

    # If the time indicates it's expired but the course doesn't
    # have an expired or closed status, then expire the course.
    if expired && !(@course.course_status_expired? || @course.course_status_closed?)
      @course.course_status_expired!

      # Handle email notifications
      @course.send_test_status_emails
    end

    return expired
  end

  # Check if the user can resume this test (even if expired)
  def can_resume(total_time)
    return is_user_resuming && get_time_left(total_time) > 0
  end

  # Check the amount of times this user has to take this test
  # If a resuming user has 0 trials left, they can still resume
  def has_trials_left(max_trials)
    return get_max_trials_left(max_trials) > 0
  end

  # Check if candidacy has been exceeded
  def has_available_test_slots(user_limit)
    return get_available_test_slots(user_limit).nil? || get_available_test_slots(user_limit) > 0
  end

  # endregion

end
