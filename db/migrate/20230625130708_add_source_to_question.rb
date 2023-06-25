class AddSourceToQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :source, :text
  end
end
