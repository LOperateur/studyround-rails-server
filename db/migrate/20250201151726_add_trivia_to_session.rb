class AddTriviaToSession < ActiveRecord::Migration[5.2]
  def change
    add_reference :sessions, :trivia_set, foreign_key: true, null: true
  end
end
