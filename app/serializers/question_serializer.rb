class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :order, :question, :question_image_url, :options,
             :multi_answer, :version, :multiplier, :year, :question_image_asset, :passage_asset

  def question_image_url
    object.generated_question_image_url
  end

  def question_image_asset
    object.question_image_asset
  end

  def passage_asset
    object.passage_asset
  end
end
