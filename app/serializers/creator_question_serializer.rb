class CreatorQuestionSerializer < QuestionAnswerSerializer
  type :question
  attributes :previous_question_id, :next_question_id, :question_raw, :explanation,
             :explanation_image_url, :explanation_raw, :remaining_edits, :notes, :draft

  belongs_to :creator, serializer: MiniProfileSerializer

  def previous_question_id
    object.previous_id
  end

  def next_question_id
    object.next_id
  end

  def explanation_image_url
    object.generated_explanation_image_url
  end

  def remaining_edits
    [6 - object.version, 5].min
  end

end
