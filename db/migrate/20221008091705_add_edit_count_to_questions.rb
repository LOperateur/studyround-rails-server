class AddEditCountToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :edit_count, :integer, default: 0
  end
end
