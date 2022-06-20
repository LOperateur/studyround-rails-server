class GroupedResultsSerializer < ActiveModel::Serializer
  attributes :course_id, :title, :latest_score, :latest_session_date

  def latest_score
    ((object.score.to_f / object.total.to_f) * 100).round(2)
  end

  def latest_session_date
    object.created_at
  end
end