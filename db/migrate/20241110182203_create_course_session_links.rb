class CreateCourseSessionLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :course_session_links do |t|
      t.references :course, foreign_key: true
      t.references :session, foreign_key: true
      t.integer :order

      t.timestamps
    end
  end
end
