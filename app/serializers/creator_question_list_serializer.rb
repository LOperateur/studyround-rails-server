class CreatorQuestionListSerializer < ActiveModel::Serializer
  type :question
  attributes :id, :question, :draft

  def draft
    if object.draft.present?
      { question: object.draft["question"] }
    else
      nil
    end
  end
end
