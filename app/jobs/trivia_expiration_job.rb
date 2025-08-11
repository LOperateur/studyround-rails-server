class TriviaExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expired_trivia_sets = TriviaSet.where({ trivia_status: :active }).where("expiration < ?", Time.now)

    expired_trivia_sets.each do |trivia|
      begin
        # Expire all these tests that their expiration dates have passed
        trivia.trivia_status_expired!

        # Handle email notifications
        trivia.send_trivia_status_emails
      rescue => e
        logger.error("TriviaExpirationJob for trivia_set_id #{trivia.id} with error: #{e}")
      end
    end
  end
end
