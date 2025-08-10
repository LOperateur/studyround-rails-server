class TriviaInvitationSerializer < ActiveModel::Serializer
  attributes :id, :email, :invited_at, :invite_honored

  belongs_to :user, serializer: MiniProfileSerializer, if: -> { object.user.present? }

  def invited_at
    object.created_at
  end

  def invite_honored
    return false unless object.user.present?

    # Check if user has any sessions or results for this test
    trivia = object.trivia_set
    user = object.user

    has_session = trivia.sessions.exists?(user: user)
    has_result = trivia.results.exists?(user: user)

    has_session || has_result
  end
end