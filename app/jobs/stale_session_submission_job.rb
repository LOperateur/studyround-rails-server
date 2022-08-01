class StaleSessionSubmissionJob < ApplicationJob
  include TestHelper
  queue_as :default

  def perform
    recent_sessions = Session.where({ session_type: :test }).created_after(48.hours.ago)

    recent_sessions.each do |session|
      begin
        # Sessions that cannot be updated are considered stale
        if check_session_for_valid_update(session).nil?
          get_end_test_result(session.user, session.course)
        end
      rescue Errors::BaseError
        # Ignored
      end
    end
  end
end
