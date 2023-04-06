class AddPreviousIdAndNextIdToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_reference :questions, :previous, foreign_key: { to_table: :questions }, index: false
    add_reference :questions, :next, foreign_key: { to_table: :questions }, index: false
  end
end
