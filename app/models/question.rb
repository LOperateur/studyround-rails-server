class Question < ApplicationRecord
  belongs_to :course

  validates_with QuestionValidator

  has_one_attached :question_image_published, dependent: :detach # Retain history of published attachments
  has_one_attached :question_image
  has_one_attached :explanation_image_published, dependent: :detach
  has_one_attached :explanation_image
  has_many_attached :option_images_published, dependent: :detach
  has_many_attached :option_images

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

  def generated_question_image_url
    begin
      path = rails_blob_path(self.question_image_published, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      # TODO: Deprecate and remove `question_image_url`
      # If no image is attached, check for an optional db-added url
      return self.question_image_url
    end
  end

  def generated_explanation_image_url
    begin
      path = rails_blob_path(self.explanation_image_published, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      # TODO: Deprecate and remove `explanation_image_url`
      # If no image is attached, check for an optional db-added url
      return self.explanation_image_url
    end
  end

  def generated_option_image_url(order)
    # Todo
  end
end
