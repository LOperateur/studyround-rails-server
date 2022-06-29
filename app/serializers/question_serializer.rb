class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :order, :question, :question_image_url, :options,
             :multi_answer, :version, :multiplier
end
