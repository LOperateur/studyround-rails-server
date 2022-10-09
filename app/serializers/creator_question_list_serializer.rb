class CreatorQuestionListSerializer < ActiveModel::Serializer
  type :question
  attributes :id, :question, :draft

  def draft
    { question: object.draft["question"] }
  end
end
