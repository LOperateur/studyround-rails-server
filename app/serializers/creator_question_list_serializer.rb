class CreatorQuestionListSerializer < ActiveModel::Serializer
  type :question
  attributes :id, :question, :draft, :notes

  belongs_to :creator, serializer: MiniProfileSerializer

  def draft
    if object.draft.present?
      { question: object.draft["question"] }
    else
      nil
    end
  end
end
