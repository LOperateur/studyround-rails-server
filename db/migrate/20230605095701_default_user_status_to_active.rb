class DefaultUserStatusToActive < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :user_status, :integer, default: 1
  end
end
