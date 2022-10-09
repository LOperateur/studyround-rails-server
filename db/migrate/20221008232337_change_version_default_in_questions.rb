class ChangeVersionDefaultInQuestions < ActiveRecord::Migration[5.2]
  def change
    change_column_default :questions, :version, from: 1, to: 0
  end
end