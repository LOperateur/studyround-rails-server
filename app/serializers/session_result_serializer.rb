class SessionResultSerializer < ResultSerializer
  type :result
  attributes :session

  def session
    {
      num_questions: object.session_items.length,
      duration: object.duration,
      session_type: object.session_type.to_s.gsub("session_type_", ""),
      tags: object.tags
    }
  end
end
