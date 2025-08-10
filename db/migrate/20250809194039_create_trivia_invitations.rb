class CreateTriviaInvitations < ActiveRecord::Migration[5.2]
  def change
    create_table :trivia_invitations do |t|
      t.references :trivia_set, null: false, foreign_key: true
      t.string :email, null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :trivia_invitations, [:trivia_set_id, :email], unique: true
  end
end
