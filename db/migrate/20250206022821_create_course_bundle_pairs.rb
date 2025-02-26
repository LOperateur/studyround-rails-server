class CreateCourseBundlePairs < ActiveRecord::Migration[5.2]
  def change
    create_table :course_bundle_pairs do |t|
      t.references :course_bundle, foreign_key: true, null: false
      t.references :course, foreign_key: true, null: false

      t.timestamps
    end

    # Add a unique index to ensure no duplicate course-bundle pairs
    add_index :course_bundle_pairs, [:course_bundle_id, :course_id], unique: true
  end
end
