class QuestionAssetReference < ApplicationRecord
  belongs_to :question
  belongs_to :question_asset

  enum reference_type: {
    reference_type_question_image: 1,
    reference_type_question_image_draft: 2,
    reference_type_explanation_image: 3,
    reference_type_explanation_image_draft: 4,
    reference_type_option_image: 5,
    reference_type_option_image_draft: 6,
    reference_type_passage: 7,
    reference_type_passage_draft: 8,
  }
end
