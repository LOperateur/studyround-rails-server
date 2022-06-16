module TestHelper
  def init_test(user, course, instructions)
    @user = user
    @course = course
    @instructions = instructions

    instructions_array = [
      instructions_map[:private],
      instructions_map[:num_questions],
      instructions_map[:expiration],
    ]

    instructions.each do |k, v|
      instructions_array << map_instructions(k)
    end

    instructions_array.compact
  end

  private

  # region Basic private functions

  def is_resuming
    #TODO: Change to sessions
    # @user.results.where(course: @course).count > 0
    true
  end

  def map_instructions(key)
    instructions_map[key]
  end

  def instructions_map
    {
      # Default test instructions
      private: privacy_instruction,
      num_questions: num_questions_instruction,

      # Restrictive instructions
      time: map_time_instruction,
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
    uninvited_text = "This test is private, you need an invitation to partake"

    if @course.private
      check_valid_invitation ? invited_text : uninvited_text
    else
      nil
    end
  end

  def num_questions_instruction
    "There are #{@course.questions.count} questions in this test"
  end

  def expiration_instruction
    expiration = @course.test_expiration || DateTime.now.utc

    if is_expired(expiration)
      total_time = @instructions[:time]
      resumption_addendum = ""

      if is_resuming && get_time_left(total_time) > 0
        resumption_addendum = ", you are still allowed to resume."
      end

      "This test expired on #{expiration}#{resumption_addendum}"
    else
      "This test will expire on #{expiration}"
    end
  end

  def map_max_trials_instruction
    max_trials = @instructions[:max_trials]

    max_trials_left = get_max_trials_left(max_trials)

    "You have #{max_trials_left} attempts left to take this test"
  end

  def map_user_limit_instruction
    user_limit = @instructions[:user_limit]

    available_test_slots = get_available_test_slots(user_limit)

    "There are #{available_test_slots} more candidate slots left for this test"
  end

  def map_reveal_answers_instruction
    reveal_answers = @instructions[:reveal_answers]

    reveal_answers_text = "Your answers for each question would be available at the end of your test"
    hidden_answers_text = "Your answers for each question would be available after the test expires"

    reveal_answers ? reveal_answers_text : hidden_answers_text
  end

  def map_time_instruction
    total_time = @instructions[:time]

    time_left = get_time_left(total_time)

    "You have #{(time_left / 60).to_i} minutes left to take this test"
  end

  def map_extra_id_instruction
    extra_id_title = @instructions[:extra_id_title]

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
    # Todo: check if session exists and use (start time + total time) - time now
    #  If session does not exist, use total_time instead
    time_left = total_time
    return time_left
  end

  def get_max_trials_left(max_trials)
    trials_taken = @user.results.where(course: @course).count
    return (max_trials.to_i) - trials_taken
  end

  def get_available_test_slots(user_limit)
    used_sessions = Result.where(course: @course).count # TODO: Change to sessions
    used_results = Result.where(course: @course).count

    return user_limit - used_sessions - used_results
  end

  # endregion



  # region Validation Checks

  # Check if it's a private test and if the user was invited
  def check_valid_invitation
    # Todo: Validate Invitation properly
    !!params[:invite_key]
  end

  # Check if the test has been closed by the creator
  # The user cannot start or resume a closed test
  def check_if_closed

  end

  # Check if the test has expired
  # The user cannot start an expired but can resume one
  def is_expired(expiration)
    expired = DateTime.now > expiration

    # If the time indicates it's expired but the course doesn't
    # have an expired or closed status, then expire the course.
    if expired && !(@course.course_status_expired? || @course.course_status_closed?)
      # TODO: Uncomment later
      # @course.course_status_expired!
    end

    return expired
  end

  # Check if the user can resume this expired test
  def check_expiry_resumption

  end

  # Check the amount of times this user has to take this test
  # If a resuming user has 0 trials left, they can still resume
  def check_trials_left

  end

  # Check if the user is resuming this test
  # and also if they still have time to resume
  def check_if_resuming

  end

  # Check if candidacy has been exceeded
  def check_available_test_slots

  end

  # endregion

end
