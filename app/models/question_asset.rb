class QuestionAsset < ApplicationRecord
  include Rails.application.routes.url_helpers

  before_save :ensure_content_signature

  belongs_to :course
  belongs_to :creator, class_name: 'User'
  has_many :question_asset_references, dependent: :restrict_with_exception # Prevent deletion if referenced by a question
  has_many :questions, through: :question_asset_references
  has_one_attached :file, dependent: :purge_later # Purge the file if the asset is deleted

  # Todo: Explore attachment_changes.any? in Rails 6
  attr_accessor :file_changed # track file changes to update content signature

  # Name can only contain letters, numbers, underscores, and dashes and spaces
  validates :name, format: { with: /\A[a-zA-Z0-9_\- ]+\z/, message: "can only contain letters, numbers, underscores, dashes, and spaces" },
            length: { maximum: 50 }, presence: true

  enum asset_type: {
    asset_type_image: 1,
    asset_type_passage: 2,
  }

  # Used to serialize the question asset model on the go without having to render
  def serialized_question_asset
    QuestionAssetSerializer.new(self).as_json
  end

  def generated_asset_file_url
    begin
      path = rails_blob_path(self.file, only_path: true)
      return ActionController::Base.helpers.asset_path(path)
    rescue
      nil
    end
  end

  private

  def ensure_content_signature
    if self.content_signature.nil? || content_changed? || file_changed
      self.content_signature = SecureRandom.uuid
    end
  end
end
