class AuthProvider < ApplicationRecord
  belongs_to :user

  enum auth_provider: {
    auth_provider_password: 1,
    auth_provider_google: 2,
    # add more...
  }
end
