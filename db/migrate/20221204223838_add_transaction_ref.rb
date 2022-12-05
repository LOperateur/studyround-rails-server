class AddTransactionRef < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :transaction_ref, :string
    add_index :transactions, :transaction_ref, unique: true
  end
end
