class AddTagsToResults < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :tags, :jsonb
  end
end
