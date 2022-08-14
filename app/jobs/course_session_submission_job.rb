class CourseSessionSubmissionJob < ApplicationJob
  include TestHelper
  queue_as :default

  def perform(course)
    course.sessions.each do |session|
      begin
        get_end_test_result(session.user, session.course)
      rescue Errors::BaseError
        # Ignored
      end
    end
    # TODO: When used, we can send a notification after this job completes
  end
end
