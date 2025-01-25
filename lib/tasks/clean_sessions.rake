namespace :clean_sessions do

  desc 'Delete all stale study sessions'
  task delete_stale_study_sessions: :environment do
    DeleteStaleStudySessionJob.perform_later
  end
end
