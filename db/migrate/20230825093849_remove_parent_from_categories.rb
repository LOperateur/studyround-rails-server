class RemoveParentFromCategories < ActiveRecord::Migration[5.2]
  def change
    remove_reference :categories, :parent, foreign_key: { to_table: :categories }
  end
end
