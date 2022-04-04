class ChangeCourseCurrencyToString < ActiveRecord::Migration[5.2]
  def up
    change_column :courses, :currency, :string
  end

  def down
    change_column :courses, :currency, :integer, using: 'currency::integer'
  end
end
