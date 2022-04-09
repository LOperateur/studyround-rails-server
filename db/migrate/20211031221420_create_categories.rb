class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }
      t.string :name
      t.integer :level
      t.string :image_url

      t.timestamps
    end
    add_index :categories, :name, unique: true
  end
end
