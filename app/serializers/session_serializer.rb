class SessionSerializer < ActiveModel::Serializer
  attributes :id, :current_question_number, :server_time, :start_time, :course_id, :course_name, :session_items

  def start_time
    object.created_at
  end

  def server_time
    DateTime.now.utc
  end

  def course_name
    object.course.title
  end
end
