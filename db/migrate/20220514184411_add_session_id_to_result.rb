class AddSessionIdToResult < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :session_id, :bigint
    add_index :results, :session_id, unique: true
  end
end
