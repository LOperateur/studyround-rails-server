class ResultSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent, :elapsed_time, :created_at, :can_reveal_answers

  belongs_to :course, serializer: MiniCourseSerializer

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end

  def has_session_items
    # Tests never have theirs deleted
    object.session_items.blank?
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
