class QuestionAnswerSerializer < QuestionSerializer
  type :question
  attributes :answer, :has_explanation

  def has_explanation
    object.explanation.present?
    # Todo: Consider this in future
    # object.explanation.present? || object.explanation_image_asset.present?
  end
end
