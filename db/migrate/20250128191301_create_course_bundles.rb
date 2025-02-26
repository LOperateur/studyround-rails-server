class CreateCourseBundles < ActiveRecord::Migration[5.2]
  def change
    create_table :course_bundles do |t|
      t.string :name
      t.text :description
      t.references :creator, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
