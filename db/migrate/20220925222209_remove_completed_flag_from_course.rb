class RemoveCompletedFlagFromCourse < ActiveRecord::Migration[5.2]
  def change
    remove_column :courses, :completed, :boolean
  end
end
