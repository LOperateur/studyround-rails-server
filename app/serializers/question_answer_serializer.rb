class QuestionAnswerSerializer < QuestionSerializer
  type :question
  attributes :answer, :answer_image_url
end
