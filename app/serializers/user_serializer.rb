class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :first_name, :last_name,
             :other_name, :date_of_birth, :creator, :pro_account,
             :occupation, :country, :profile_image_url, :user_type,
             :onboarding, :about

  def profile_image_url
    object.generated_profile_image_url ||
      object.auth_providers.where.not(auth_provider: :auth_provider_password).first&.metadata&.dig('avatar')
  end

  def user_type
    object.user_type
  end

  def onboarding
    {
      interests: false,
      dashboard: false,
      course_list: false,
      session_start: false,
      manage_course: false,
      manage_question: false,
    }.merge(object.onboarding)
  end
end
