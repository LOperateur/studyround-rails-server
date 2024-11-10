class ResultSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent, :elapsed_time, :created_at, :can_reveal_answers, :has_session_items, :courses

  def courses
    if object.course.present?
      [object.course.serialized_mini_course]
    else
      object.multi_courses.map do |course|
        course.serialized_mini_course
      end
    end
  end

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end

  def has_session_items
    # Tests never have their session items deleted
    object.session_items.present?
  end

  def can_reveal_answers
    can_reveal_answers = true
    if object.session_type_test?
      course = object.course
      # Restrict session item access if reveal answers is false and the course isn't closed yet
      if !course.instructions['reveal_answers'] && !course.course_status_closed?
        can_reveal_answers = false
      end
    end

    return can_reveal_answers
  end
end
