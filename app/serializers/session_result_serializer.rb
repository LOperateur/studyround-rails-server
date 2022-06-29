class SessionResultSerializer < ResultSerializer
  type :result
  attributes :session

  def session
    {
      # Todo: session items length check is temporary, remove later
      num_questions: object.num_questions || object.session_items.length,
      duration: object.duration,
      session_type: object.session_type,
      tags: object.tags
    }
  end
end
