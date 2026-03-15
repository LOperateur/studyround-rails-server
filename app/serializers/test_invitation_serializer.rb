class TestInvitationSerializer < ActiveModel::Serializer
  attributes :id, :email, :invited_at, :invite_honored

  belongs_to :user, serializer: MiniProfileSerializer, if: -> { object.user.present? }

  def invited_at
    object.created_at
  end

  def invite_honored
    user = object.user || User.find_by(email: object.email)
    return false if !user.present?

    # Check if user has any sessions or results for this test
    course = object.course

    has_session = course.sessions.exists?(user: user)
    has_result = course.results.exists?(user: user)

    has_session || has_result
  end
end
