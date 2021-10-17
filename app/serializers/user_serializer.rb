class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :first_name, :last_name,
             :other_name, :date_of_birth, :creator, :pro_account,
             :occupation, :country, :profile_image_url, :about
end
