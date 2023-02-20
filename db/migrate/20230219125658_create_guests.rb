class CreateGuests < ActiveRecord::Migration[5.2]
  def change
    create_table :guests do |t|
      t.string :email
      t.jsonb :result

      t.timestamps
    end
    add_index :guests, :email, unique: true
  end
end
