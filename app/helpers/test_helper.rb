module TestHelper
  def init_test_instructions(user, course)
    @user = user
    @course = course
    # Todo: Get from course
    @instructions = instructions = {
      max_trials: 1,
      reveal_answers: true,
      time: 7200,
      extra_id_title: "Mat Number",
      user_limit: 100,
      graded: true,
      pause_on_quit: false,
    }

    @current_session = user.sessions.find_by(course: course)

    instructions_array = [
      instructions_map[:private],
      instructions_map[:num_questions],
      instructions_map[:expiration],
    ]

    instructions.each do |k, v|
      instructions_array << map_instructions(k)
    end

    course.serialized_mini_course.merge(
      {
        resuming: is_user_resuming,
        server_time: DateTime.now.utc,
        time_left: get_time_left(instructions[:time]),
        start_time: if is_user_resuming then @current_session.created_at else nil end,
        duration: instructions[:time],
        attempts_left: get_max_trials_left(instructions[:max_trials]),
        extra_id_title: instructions[:extra_id_title],
        instructions: is_closed ? ["This test has been ended"] : instructions_array.compact
      }
    )
  end

  def start_test(user, course)
    @user = user
    @course = course
    # Todo: Get from course
    @instructions = instructions = {
      max_trials: 1,
      reveal_answers: true,
      time: 7200,
      extra_id_title: "Mat Number",
      user_limit: 100,
      graded: true,
      pause_on_quit: false,
    }

    @current_session = user.sessions.find_by(course: course)

  end

  private

  # region Basic private functions

  def map_instructions(key)
    instructions_map[key]
  end

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
    # Default expiration is 30 days from creation
    expiration = @course.test_expiration || @course.created_at + 30.days

    if is_expired(expiration)
      total_time = @instructions[:time]
      resumption_addendum = ""

      if can_resume(total_time)
        resumption_addendum = ", you are still allowed to resume."
      end

      "This test expired on #{expiration.to_formatted_s(:long_ordinal)}#{resumption_addendum}"
    else
      "This test will expire on #{expiration.to_formatted_s(:long_ordinal)}"
    end
  end

  def map_max_trials_instruction
    max_trials = @instructions[:max_trials]

    max_trials_left = get_max_trials_left(max_trials)

    "You have #{max_trials_left} chances left to take and submit this test"
  end

  def map_user_limit_instruction
    user_limit = @instructions[:user_limit]

    available_test_slots = get_available_test_slots(user_limit)

    if available_test_slots.nil?
      return nil
    end

    "There are #{available_test_slots} more candidate slots left for this test"
  end

  def map_reveal_answers_instruction
    reveal_answers = @instructions[:reveal_answers]

    reveal_answers_text = "Your answers for each question would be available at the end of your test"
    hidden_answers_text = "Your answers for each question would be available after the test expires"

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
      time_left = @current_session.created_at + (@current_session.duration).seconds - DateTime.now
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

  # Check if it's a private test and if the user was invited
  def has_valid_invitation
    # Todo: Validate Invitation properly
    return !!params[:invite_key]
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
    expired = DateTime.now > expiration

    # If the time indicates it's expired but the course doesn't
    # have an expired or closed status, then expire the course.
    if expired && !(@course.course_status_expired? || @course.course_status_closed?)
      @course.course_status_expired!
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
  def has_available_test_slots(test_slots)
    return get_available_test_slots(test_slots).nil? || get_available_test_slots(test_slots) > 0
  end

  # endregion

end
