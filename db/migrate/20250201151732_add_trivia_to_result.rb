class AddTriviaToResult < ActiveRecord::Migration[5.2]
  def change
    add_reference :results, :trivia_set, foreign_key: true, null: true
  end
end
