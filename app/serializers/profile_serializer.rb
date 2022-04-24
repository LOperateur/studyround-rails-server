class ProfileSerializer < ActiveModel::Serializer
  attributes :id, :username, :profile_image_url, :first_name, :last_name, :email, :pro_account, :country
end
