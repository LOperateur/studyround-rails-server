class Question < ApplicationRecord
  include Rails.application.routes.url_helpers
  belongs_to :course

  belongs_to :previous, class_name: "Question", foreign_key: :previous_id, optional: true
  belongs_to :next, class_name: "Question", foreign_key: :next_id, optional: true
  belongs_to :creator, class_name: "User", foreign_key: :creator_id, optional: true

  has_many :question_asset_references, dependent: :destroy # Delete all asset references if question is deleted
  has_many :question_assets, through: :question_asset_references

  validates_with QuestionValidator

  # Todo: Deprecated - Remove these eventually starting with the drafts
  has_one_attached :question_image, dependent: :purge_later
  has_one_attached :question_image_draft, dependent: :purge_later
  has_one_attached :explanation_image, dependent: :purge_later
  has_one_attached :explanation_image_draft, dependent: :purge_later

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

  scope :filtered_by_year, -> (year) { year.present? ? where(year: year) : all }
  scope :filtered_by_draft_year, -> (year) {
    if year.present?
      # Get all questions that have a draft with the year or no draft but the year in the question column
      where("draft->>'year' = ? OR (draft IS NULL AND year = ?)", year, year)
    else
      all
    end
  }

  # Used to serialize the question model on the go without having to render
  def serialized_question
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionSerializer).as_json
  end

  def serialized_question_with_answer
    ActiveModelSerializers::SerializableResource.new(self, serializer: QuestionAnswerSerializer).as_json
  end

  def serialized_creator_question_list_item
    ActiveModelSerializers::SerializableResource.new(self, serializer: CreatorQuestionListSerializer).as_json
  end

  # Assets
  def question_image_asset
    # Get the question asset with a reference type of reference_type_question_image
    self.question_asset_references.find_by(reference_type: :reference_type_question_image)&.question_asset&.serialized_question_asset
  end

  def explanation_image_asset
    # Get the question asset with a reference type of reference_type_explanation_image
    self.question_asset_references.find_by(reference_type: :reference_type_explanation_image)&.question_asset&.serialized_question_asset
  end

  def passage_asset
    # Get the question asset with a reference type of reference_type_passage
    self.question_asset_references.find_by(reference_type: :reference_type_passage)&.question_asset&.serialized_question_asset
  end

  @deprecated # Use question_assets instead
  def generated_question_image_url
    begin
      path = rails_blob_path(self.question_image, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end

  @deprecated # Use question_assets instead
  def generated_explanation_image_url
    begin
      path = rails_blob_path(self.explanation_image, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end

  def remove_linked_self_references
    Question.transaction do
      # Update position of adjacent questions before this deletion
      previous_question = self.previous
      next_question = self.next

      if previous_question
        previous_question.update!(next_id: self.next_id)
      end

      if next_question
        next_question.update!(previous_id: self.previous_id)
      end
    end
  end
end
