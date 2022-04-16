class ResultSerializer < ActiveModel::Serializer
  attributes :id, :score, :total, :percent, :created_at

  def percent
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end
end
