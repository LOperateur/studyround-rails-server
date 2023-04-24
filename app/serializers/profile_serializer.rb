class ProfileSerializer < ActiveModel::Serializer
  type :user
  attributes :id, :username, :profile_image_url, :first_name,
             :last_name, :email, :pro_account, :country, :user_type

  def profile_image_url
    object.generated_profile_image_url
  end

  def user_type
    object.user_type
  end
end