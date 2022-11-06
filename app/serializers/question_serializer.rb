class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :order, :question, :question_image_url, :options,
             :multi_answer, :version, :multiplier

  def question_image_url
    object.generated_question_image_url
  end
end
