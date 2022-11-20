class RemoveProfileImageUrlFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :profile_image_url, :string
  end
end
