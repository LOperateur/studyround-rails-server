class AddNumberOfQuestionsToResult < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :num_questions, :integer
  end
end
