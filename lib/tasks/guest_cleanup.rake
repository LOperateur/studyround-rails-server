namespace :guests do

  desc 'Cleanup all irrelevant Guest data'
  task cleanup_guest_data: :environment do
    CleanupGuestDataJob.perform_later
  end
end
