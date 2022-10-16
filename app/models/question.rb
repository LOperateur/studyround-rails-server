class Question < ApplicationRecord
  belongs_to :course

  validates_with QuestionValidator

  # has_one_attached :question_image
  # has_one_attached :question_image_draft
  # has_one_attached :explanation_image
  # has_one_attached :explanation_image_draft
  # has_many_attached :option_images
  # has_many_attached :option_images_draft

  enum publish_status: {
    publish_status_draft: 1,
    publish_status_published: 2,
  }

  enum question_status: {
    question_status_active: 1,
    question_status_suspended: 2,
    question_status_deleted: 3,
  }

  scope :published_active_questions, -> { where(publish_status: :publish_status_published, question_status: :question_status_active) }
  scope :non_deleted_questions, -> { where.not(question_status: :question_status_deleted) }

  # Used to serialize the question model on the go without having to render
  def serialized_question
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionSerializer).as_json
  end

  def serialized_question_with_answer
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionAnswerSerializer).as_json
  end
end
