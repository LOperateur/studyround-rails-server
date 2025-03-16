class DefaultTriviaStatusToActive < ActiveRecord::Migration[5.2]
  def change
    change_column_default :trivia_sets, :trivia_status, from: nil, to: 1
  end
end
