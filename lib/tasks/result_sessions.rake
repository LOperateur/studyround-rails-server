namespace :result_sessions do

  desc 'Delete all result sessions that are older than 30 days'
  task delete_result_sessions: :environment do
    DeleteExpiredResultSessionJob.perform_later
  end
end
