class CreateResults < ActiveRecord::Migration[5.2]
  def change
    create_table :results do |t|
      t.references :user, foreign_key: true
      t.references :course, foreign_key: true
      t.integer :score
      t.integer :total
      t.bigint :duration
      t.integer :mode
      t.string :extra_id
      t.jsonb :session_items

      t.timestamps
    end
  end
end
