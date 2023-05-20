class AddNotesToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :notes, :jsonb
  end
end
