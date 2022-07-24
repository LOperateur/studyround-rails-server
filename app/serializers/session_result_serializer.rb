class SessionResultSerializer < ResultSerializer
  type :result
  attributes :session

  def session
    {
      num_questions: object.num_questions || nil,
      duration: object.duration,
      session_type: object.session_type,
      tags: object.tags
    }
  end
end
