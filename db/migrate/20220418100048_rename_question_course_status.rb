class RenameQuestionCourseStatus < ActiveRecord::Migration[5.2]
  def change
    rename_column :courses, :draft, :publish_status
    rename_column :questions, :status, :publish_status
  end
end
