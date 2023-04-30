class AddOnboardingToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :onboarding, :jsonb, default: {}
  end
end
