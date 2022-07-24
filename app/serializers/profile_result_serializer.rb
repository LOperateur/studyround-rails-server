class ProfileResultSerializer < ResultSerializer
  type :result
  attributes :extra_id

  belongs_to :user, serializer: ProfileSerializer
end
