class Question < ApplicationRecord
  belongs_to :course

  enum publish_status: {
    publish_status_draft: 1,
    publish_status_published: 2,
  }

  # Used to serialize the question model on the go without having to render
  def serialized_question
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionSerializer).as_json
  end

  def serialized_question_with_answer
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionAnswerSerializer).as_json
  end
end
