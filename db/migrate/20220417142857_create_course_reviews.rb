class CreateCourseReviews < ActiveRecord::Migration[5.2]
  def change
    create_table :course_reviews do |t|
      t.references :course, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :rating
      t.text :review

      t.timestamps
    end
  end
end
