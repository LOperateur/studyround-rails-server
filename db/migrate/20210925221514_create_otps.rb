class CreateOtps < ActiveRecord::Migration[5.2]
  def change
    create_table :otps do |t|
      t.string :user_identity
      t.string :otp
      t.integer :auth_type
      t.integer :tries

      t.timestamps
    end
    add_index :otps, :user_identity, unique: true
  end
end
