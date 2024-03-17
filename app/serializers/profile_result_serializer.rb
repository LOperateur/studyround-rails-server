class ProfileResultSerializer < ResultSerializer
  type :result
  attributes :extra_id, :disqualified

  belongs_to :user, serializer: ProfileSerializer

  def disqualified
    object.disqualified
  end
end
