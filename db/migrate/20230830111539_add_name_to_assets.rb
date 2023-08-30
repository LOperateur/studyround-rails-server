class AddNameToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :question_assets, :name, :string
  end
end
