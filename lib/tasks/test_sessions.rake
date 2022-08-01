namespace :test_sessions do

  desc 'Marks all tests as expired if they\'re past their expiration dates'
  task expire_tests: :environment do
    TestExpirationJob.perform_later
  end

  desc 'Submits all stale sessions, converting them to results'
  task submit_stale_sessions: :environment do
    StaleSessionSubmissionJob.perform_later
  end
end
