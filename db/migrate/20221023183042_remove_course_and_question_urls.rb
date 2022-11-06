class RemoveCourseAndQuestionUrls < ActiveRecord::Migration[5.2]
  def change
    remove_column :courses, :image_url, :string
    remove_column :questions, :question_image_url, :string
    remove_column :questions, :explanation_image_url, :string
  end
end
