class CreateQuestionAssetReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :question_asset_references do |t|
      t.references :question, foreign_key: true
      t.references :question_asset, foreign_key: true
      t.integer :reference_type

      t.timestamps
    end
  end
end
