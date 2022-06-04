class RenameResultSessionIdToSessionKey < ActiveRecord::Migration[5.2]
  def change
    rename_column :results, :session_id, :session_key
  end
end
