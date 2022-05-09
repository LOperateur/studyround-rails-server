class QuestionSerializer < ActiveModel::Serializer
  attributes :id, :order, :question, :question_image_url, :options,
             :answer, :answer_image_url, :multi_answer, :version, :multiplier
end
