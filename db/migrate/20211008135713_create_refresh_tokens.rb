class CreateRefreshTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :refresh_tokens do |t|
      t.string :token
      t.references :user, index: {:unique=>true}, foreign_key: true

      t.timestamps
    end
  end
end
