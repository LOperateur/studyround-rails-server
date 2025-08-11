class CreateTestInvitations < ActiveRecord::Migration[5.2]
  def change
    create_table :test_invitations do |t|
      t.references :course, null: false, foreign_key: true
      t.string :email, null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :test_invitations, [:course_id, :email], unique: true
  end
end
