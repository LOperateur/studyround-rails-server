class ChangeResultSessionIdToString < ActiveRecord::Migration[5.2]
  def up
    change_column :results, :session_id, :string
  end

  def down
    change_column :results, :session_id, :bigint, using: "NULL"
  end
end
