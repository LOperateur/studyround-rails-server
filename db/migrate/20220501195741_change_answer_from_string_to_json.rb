class ChangeAnswerFromStringToJson < ActiveRecord::Migration[5.2]
  def change
    remove_column :questions, :answer, :string
    add_column :questions, :answer, :jsonb
  end
end
