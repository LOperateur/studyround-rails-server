class TestExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expired_tests = Course.where({ test: true, course_status: :course_status_active }).where("test_expiration < ?", Time.now)

    expired_tests.each do |test|
      begin
        # Expire all these tests that their expiration dates have passed
        # TODO: Also send a notification to the creator
        test.course_status_expired!
      rescue Errors::BaseError
        # Ignored
      end
    end
  end
end
