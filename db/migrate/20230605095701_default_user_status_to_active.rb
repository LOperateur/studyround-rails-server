class DefaultUserStatusToActive < ActiveRecord::Migration[5.2]
  def change
    change_column_default :users, :user_status, from: nil, to: 1
  end
end
