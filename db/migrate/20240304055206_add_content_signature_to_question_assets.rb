class AddContentSignatureToQuestionAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :question_assets, :content_signature, :string
    add_index :question_assets, :content_signature
  end
end
