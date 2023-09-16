class AddCreatorToAssets < ActiveRecord::Migration[5.2]
  def change
    add_reference :question_assets, :creator, foreign_key: { to_table: :users }
  end
end
