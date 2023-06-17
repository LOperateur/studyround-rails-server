class CreateQuestionAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :question_assets do |t|
      t.references :course, foreign_key: true
      t.text :content
      t.integer :asset_type

      t.timestamps
    end
  end
end
