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
    # They are currently keys in an env var that's a string delimited by pipes |
    # An array of pairs can be converted to a hash with `to_h`
    default_onboarding = ENV['ONBOARDING_PARAMS'].split('|').map { |param| [param, false] }.to_h
    default_onboarding.merge(object.onboarding)
  end
end
