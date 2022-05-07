class RenameQuestionNumberToOrder < ActiveRecord::Migration[5.2]
  def change
    rename_column :questions, :question_number, :order
  end
end
