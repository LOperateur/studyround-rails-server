class CreateCourses < ActiveRecord::Migration[5.2]
  def change
    create_table :courses do |t|
      t.references :creator, foreign_key: { to_table: :users }
      t.string :title
      t.integer :sale_status
      t.string :sub_topics
      t.decimal :price, precision: 10, scale: 2
      t.integer :currency
      t.boolean :private
      t.boolean :test
      t.text :about
      t.string :image_url
      t.integer :version
      t.datetime :test_expiration
      t.boolean :draft
      t.jsonb :draft_content
      t.integer :course_status
      t.integer :next_edition
      t.integer :previous_edition
      t.integer :rating
      t.jsonb :instructions
      t.boolean :completed

      t.timestamps
    end
    add_index :courses, :title
  end
end
