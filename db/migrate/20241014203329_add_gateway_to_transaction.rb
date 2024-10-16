class AddGatewayToTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :gateway, :string
  end
end
