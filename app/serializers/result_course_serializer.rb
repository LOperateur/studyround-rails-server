class ResultCourseSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent
  belongs_to :course

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end
end
