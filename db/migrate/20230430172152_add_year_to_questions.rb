class AddYearToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :year, :string
  end
end
