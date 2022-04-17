class ChangeQuestionFieldsToText < ActiveRecord::Migration[5.2]
  def up
    change_column :questions, :question, :text
    change_column :questions, :explanation, :text
  end

  def down
    change_column :questions, :question, :string
    change_column :questions, :explanation, :string
  end
end
