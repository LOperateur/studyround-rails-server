class RemoveDraftContentFromCourses < ActiveRecord::Migration[5.2]
  def change
    remove_column :courses, :draft_content, :jsonb
  end
end
