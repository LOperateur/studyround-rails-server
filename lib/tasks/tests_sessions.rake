namespace :tests_sessions do

  task expire_tests: :environment do
    TestExpirationJob.perform_later
  end

  task submit_stale_sessions: :environment do
    StaleSessionSubmissionJob.perform_later
  end
end
