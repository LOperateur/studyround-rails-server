class Session < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :course

  enum session_type: {
    quiz: 1,
    practice: 2,
    study: 3,
    test: 4,
  }, _prefix: true

  # Used to serialize the session model on the go without having to render
  def serialized_session
    ActiveModelSerializers::SerializableResource.new(self, serializer: SessionSerializer).as_json
  end
end
