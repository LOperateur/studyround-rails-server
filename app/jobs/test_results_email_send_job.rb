class TestResultsEmailSendJob < ApplicationJob
  queue_as :default

  def perform(course)
    course.results.each do |result|
      result.send_test_completion_email
    end
  end
end
