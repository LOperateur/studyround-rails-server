class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.references :buyer, foreign_key: { to_table: :users }
      t.references :seller, foreign_key: { to_table: :users }
      t.bigint :purchase_item_id
      t.integer :purchase_item_type
      t.string :purchase_currency
      t.decimal :purchase_price, precision: 10, scale: 2
      t.integer :transaction_status
      t.integer :payment_method
      t.string :description
      t.string :external_txn_id
      t.datetime :completed_at
      t.jsonb :extra
      t.string :transaction_ref

      t.timestamps
    end
    add_index :transactions, :transaction_ref, unique: true
  end
end
