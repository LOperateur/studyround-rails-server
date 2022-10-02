class AddStatusAndDefaultsToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :question_status, :integer, default: 1
    change_column_default :questions, :publish_status, from: nil, to: 1
  end
end
