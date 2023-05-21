class AddCreatorToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_reference :questions, :creator, foreign_key: { to_table: :users }
  end
end
