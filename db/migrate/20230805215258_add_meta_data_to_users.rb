class AddMetaDataToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :metadata, :jsonb, default: {}
  end
end
