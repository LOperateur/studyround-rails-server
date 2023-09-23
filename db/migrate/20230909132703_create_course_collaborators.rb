class CreateCourseCollaborators < ActiveRecord::Migration[5.2]
  def change
    create_table :course_collaborators do |t|
      t.references :course, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end
  end
end
