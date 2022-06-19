class CreateSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions do |t|
      t.references :user, foreign_key: true
      t.references :course, foreign_key: true
      t.string :extra_id
      t.bigint :duration
      t.integer :current_question_number, default: 1
      t.integer :session_type
      t.string :device_id
      t.string :web_tab_id
      t.jsonb :session_items

      t.timestamps
    end
  end
end
