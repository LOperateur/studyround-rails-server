class DeleteStaleStudySessionJob < ApplicationJob
  queue_as :default

  def perform
    Session.where("created_at < ?", Time.now - 30.days).where(session_type: :study).destroy_all
  end
end
