class CreatorQuestionSerializer < QuestionAnswerSerializer
  type :question
  attributes :question_raw, :explanation, :explanation_image_url, :explanation_raw,
             :remaining_edits, :draft

  def remaining_edits
    [6 - object.version, 5].min
  end

end
