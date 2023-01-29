class RemoveSellerIdFromTransaction < ActiveRecord::Migration[5.2]
  def change
    remove_reference :transactions, :seller, index: true, foreign_key: { to_table: :users }
  end
end
