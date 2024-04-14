class AddCreatorStatusToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :creator_status, :integer, default: 1
  end
end
