class ResultSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent, :elapsed_time, :created_at, :course

  belongs_to :course, serializer: MiniCourseSerializer

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end
end
