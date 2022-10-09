class AddRawFieldsToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :question_raw, :jsonb
    add_column :questions, :explanation_raw, :jsonb
  end
end
