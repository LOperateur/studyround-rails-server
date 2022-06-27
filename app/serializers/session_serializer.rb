class SessionSerializer < ActiveModel::Serializer
  attributes :id, :current_question_number, :server_time, :start_time, :session_items

  belongs_to :course, serializer: MiniCourseSerializer

  def start_time
    object.created_at
  end

  def server_time
    DateTime.now.utc
  end
end
