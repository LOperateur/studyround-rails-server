class ProfileResultSerializer < ResultSerializer
  type :result

  belongs_to :user, serializer: ProfileSerializer
end
