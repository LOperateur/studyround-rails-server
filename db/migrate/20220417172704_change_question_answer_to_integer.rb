class ChangeQuestionAnswerToInteger < ActiveRecord::Migration[5.2]
  def up
    change_column :questions, :answer, :integer, using: 'answer::integer'
  end

  def down
    change_column :questions, :answer, :string
  end
end
