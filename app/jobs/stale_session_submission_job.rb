class StaleSessionSubmissionJob < ApplicationJob
  include TestHelper
  include TriviaHelper
  queue_as :default

  def perform
    # Finished sessions are those that the Time now has passed their creation + duration
    finished_sessions = Session.where("created_at + interval '1 second' * duration < ?", Time.now)

    finished_sessions.each do |session|
      begin
        if session.session_type_test?
          # Finished sessions for test should be converted to results
          get_end_test_result(session.user, session.course)
        elsif session.session_type_trivia?
          get_end_trivia_result(session.user, session.trivia_set)
        else
          # Finished sessions for quiz/practice should just be deleted
          session.destroy
        end
      rescue => e
        logger.error("StaleSessionSubmissionJob for session_id #{session.id} with error: #{e}")
      end
    end
  end
end
