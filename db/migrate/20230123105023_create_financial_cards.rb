class CreateFinancialCards < ActiveRecord::Migration[5.2]
  def change
    create_table :financial_cards do |t|
      t.string :country
      t.string :expiry
      t.string :first_six
      t.string :issuer
      t.string :last_four
      t.string :card_type
      t.string :token
      t.string :provider
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :financial_cards, :token, unique: true
  end
end
