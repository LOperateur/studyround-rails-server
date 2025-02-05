class CreateTriviaSets < ActiveRecord::Migration[5.2]
  def change
    create_table :trivia_sets do |t|
      t.string :title
      t.text :subtitle
      t.jsonb :course_ids, default: []
      t.jsonb :course_bundle_ids, default: []
      t.references :creator, foreign_key: { to_table: :users }
      t.jsonb :rules
      t.jsonb :dq_results, default: []
      t.boolean :private
      t.integer :trivia_status
      t.datetime :expiration

      t.timestamps
    end
  end
end
