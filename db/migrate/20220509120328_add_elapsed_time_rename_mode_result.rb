class AddElapsedTimeRenameModeResult < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :elapsed_time, :bigint
    rename_column :results, :mode, :session_type
  end
end
