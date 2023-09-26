class CleanupGuestDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Remove the results from Guests that are older than 30 days
    Guest.where("created_at < ?", Time.now - 30.days).update_all(result: nil)

    # And clean up Guests with no email and are older than 1 hour
    Guest.where("created_at < ?", Time.now - 1.hour).where(email: nil).destroy_all
  end
end
