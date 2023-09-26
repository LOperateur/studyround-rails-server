class DeleteExpiredResultSessionJob < ApplicationJob
  queue_as :default

  def perform
    # Remove the session_items from Results that are older than 30 days and where it is not a test
    Result.where("created_at < ?", Time.now - 30.days).where.not(session_type: :test).update_all(session_items: nil)
  end
end
