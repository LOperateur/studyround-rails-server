class CreateCourseResultLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :course_result_links do |t|
      t.references :course, foreign_key: true
      t.references :result, foreign_key: true
      t.integer :order

      t.timestamps
    end
  end
end
