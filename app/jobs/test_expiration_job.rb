class TestExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expired_tests = Course.where({ test: true, course_status: :course_status_active }).where("test_expiration < ?", Time.now)

    expired_tests.each do |test|
      begin
        # Expire all these tests that their expiration dates have passed
        test.course_status_expired!

        # Handle email notifications
        test.send_test_status_emails
      rescue => e
        logger.error("TestExpirationJob for test_id #{test.id} with error: #{e}")
      end
    end
  end
end
