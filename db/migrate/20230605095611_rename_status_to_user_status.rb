class RenameStatusToUserStatus < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :status, :user_status
  end
end
