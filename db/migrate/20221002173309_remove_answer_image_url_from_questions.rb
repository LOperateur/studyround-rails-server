class RemoveAnswerImageUrlFromQuestions < ActiveRecord::Migration[5.2]
  def change
    remove_column :questions, :answer_image_url, :string
  end
end
