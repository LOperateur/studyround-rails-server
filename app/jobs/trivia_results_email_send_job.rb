class TriviaResultsEmailSendJob < ApplicationJob
  queue_as :default

  def perform(trivia)
    trivia.results.each do |result|
      result.send_trivia_completion_email
    end
  end
end
