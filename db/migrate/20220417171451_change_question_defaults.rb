class ChangeQuestionDefaults < ActiveRecord::Migration[5.2]
  def change
    change_column_default :questions, :multi_answer, from: nil, to: false
    change_column_default :questions, :multiplier, from: nil, to: 1
  end
end
