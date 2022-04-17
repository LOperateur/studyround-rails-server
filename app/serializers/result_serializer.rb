class ResultSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent, :course_title, :created_at

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end

  def course_title
    object.course.title
  end
end
