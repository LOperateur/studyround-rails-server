class SessionSerializer < ActiveModel::Serializer
  attributes :id, :current_question_number, :server_time, :start_time, :extra_id, :courses, :session_items

  def courses
    if object.course.present?
      [object.course.serialized_mini_course]
    else
      object.multi_courses.map do |course|
        course.serialized_mini_course
      end
    end
  end

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
