class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :username
      t.string :password_digest
      t.string :first_name
      t.string :last_name
      t.string :other_name
      t.string :email
      t.date :date_of_birth
      t.boolean :creator
      t.integer :status
      t.string :occupation
      t.string :country
      t.boolean :pro_account
      t.string :profile_image_url
      t.text :about
      t.boolean :certified
      t.jsonb :preferences

      t.timestamps
    end
    add_index :users, :username, unique: true
  end
end
