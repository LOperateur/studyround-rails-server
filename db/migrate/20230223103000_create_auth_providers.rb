class CreateAuthProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :auth_providers do |t|
      t.references :user, foreign_key: true
      t.integer :auth_provider
      t.jsonb :metadata

      t.timestamps
    end
  end
end
